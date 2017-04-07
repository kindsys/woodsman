require 'active_support/backtrace_cleaner'
require 'benchmark'

module Woodsman
# TODO: add statsd integration for events
# NOTE: if we relax definition of scrubbing and allow the scrub to modify the object
# in the MDC permanently and at the time of inclusion, we can get much better performance.
# Doing it the safe way for now.
  class Logger
    class << self
      # Flags controlling the output. All flags are off by default.
      # stats: enables/disables logging event metrics to statsd
      # prefix: enables/disables the line prefix (normally the caller information) for INFO and DEBUG. Line prefix is always added to ERROR level and above.
      # verbose_caller: enables logging of the full caller directory, file, method, and line #. You should enable this in production.
      attr_accessor :stats, :prefix, :verbose_caller

      def splunk_safe(string)
        string.to_s.gsub(/([= ])/) { |c| "&##{c.ord};" }
      end

      def flatten_context(context_hash)
        s = ' ' + context_hash.map { |k, v| "#{splunk_safe(k)}=#{splunk_safe(v)}" }.join(' ') if context_hash and context_hash.size > 0
        s ||= ''
      end
    end

    SUPPORTED_LOG_LEVELS = %i(debug info error fatal)
    MANDATORY_PREFIX_LOG_LEVELS = %i(error fatal)
    MUTEX_FOR_DIAG_CLEAR = Mutex.new

    attr_accessor :scrubbers, :backtrace_cleaner

    # TODO: consider setting default to nil. Would be cleaner to instantiate but in the general case, we want to wrap
    # Rails.logger so better to make it a conscious decision to use our StdOutLogger.
    def initialize(logger, default_scrubber_stack=true, add_backtrace_cleaner=true)
      @logger = logger
      @logger ||= StdOutLogger.new
      @scrubbers = Scrubbers::ScrubberStack.default_stack if default_scrubber_stack
      @scrubbers ||= Scrubbers::ScrubberStack.new
      initialize_backtrace_cleaner if add_backtrace_cleaner
    end

    def initialize_backtrace_cleaner
      bc = ActiveSupport::BacktraceCleaner.new
      bc.add_filter { |line| line.gsub(Rails.root.to_s, '') } if Module.const_defined?(:Rails) && ::Rails.respond_to?(:root)
      bc.add_silencer { |line| line =~ /woodsman\/logger\.rb/ }
      bc.add_silencer { |line| line =~ /benchmark\.rb/ }
      bc.add_silencer { |line| line =~ /rspec\/core/ }
      bc.add_silencer { |line| line =~ /bin\/rspec/ }
      bc.add_silencer { |line| line =~ /bin\/ruby_executable_hooks/ }
      @backtrace_cleaner = bc
    end

    def compact_caller(s)
      s = s.split('/')[-1] unless Logger.verbose_caller
      s
    end

    def scrubber_names
      @scrubbers.names
    end

    def scrub(line, context=nil)
      scrubbers.scrub(line, context)
    end

    def stacktrace(e)
      bt = @backtrace_cleaner.clean(e.backtrace) if @backtrace_cleaner
      bt ||= e.backtrace
      bt.join("\n\t")
    end

    def prefix(log_level=:info)
      return '' unless MANDATORY_PREFIX_LOG_LEVELS.include?(log_level) || Logger.prefix
      s = ''
      # Walk caller chain until we are outside this class.
      caller.each do |c|
        s = compact_caller(c) + ' ' and break unless c =~ /logger.rb/
      end
      s
    end

    # Timed log call for that automatically appends the elapsed time for a block.
    # We technically benchmark. Could also track CPU time, wait time, etc. if those are useful...
    def timed(msg, context_hash = nil, &block)
      ret = nil
      exception = nil
      start_time = Time.now.to_f
      begin
        ret = block.call if block
      rescue => e
        # Capture errors to ensure that this log entry is written
        exception = e
      ensure
        if block
          end_time = Time.now.to_f
          elapsed_time_ms = (end_time - start_time) * 1000
          elapsed_time = " elapsed_time=#{elapsed_time_ms.round(2)}"
        end

        if exception
          error_exception "#{msg}#{Logger.flatten_context context_hash}#{elapsed_time}", exception
          raise exception
        else
          info "#{prefix}#{msg}#{Logger.flatten_context context_hash}#{elapsed_time}"
        end
      end

      ret ||= self if block.nil?
      ret
    end

    # Convenience method for named events.
    def event(name, context_hash=nil, msg='', &block)
      # Prolly shouldn't do this, but it makes it so much nicer to use. :)
      msg, context_hash = context_hash, nil unless context_hash.respond_to?('each')
      msg = " #{msg}" if msg and msg.length > 0

      return timed("event=\"#{name}#{msg}\"", context_hash, &block) if msg && msg.include?(' ')
      timed("event=#{name}#{msg}", context_hash, &block)
    end

    SUPPORTED_LOG_LEVELS.each do |log_level|
      define_method(log_level) do |msg=nil, &block|
        msg = block.call if block
        msg, context = scrub("#{prefix(log_level)}#{msg}#{ndc}#{mdc}")
        @logger.send(log_level, msg) if msg
        self
      end
    end

    def error_exception(msg, e)
      msg, context = scrub("#{prefix(:error)}#{msg}#{ndc}#{mdc} exception=#{e}\nstacktrace=#{stacktrace(e)}")
      @logger.error(msg) if msg
      self
    end

    def fatal_exception(msg, e)
      msg, context = scrub("#{prefix(:fatal)}#{msg}#{ndc}#{mdc} exception=#{e}\nstacktrace=#{stacktrace(e)}")
      @logger.fatal(msg) if msg
      self
    end

    private
    # Pass any unhandled calls to the underlying logger interface (normally Rails.logger if you are using a Rails app)
    def method_missing(method, *args, &block)
      @logger.send(method, *args, &block)
    end

    # Contextual support, based on Logger's MDC.
    public
    def current_context
      ctx = Hash.new.with_indifferent_access
      ndc.context.each do |c|
        ctx.merge! c
      end
      ctx.merge! mdc.context
    end

    def mdc
      MappedDiagnosticContext
    end

    # It is not recommended to use the NDC directly unless you have a good reason to. Most logger clients should use
    # with_context, which handles the pushing and popping of the context.
    # TODO: consider removing access to any NDC operations other than with_context.
    def ndc
      NestedDiagnosticContext
    end

    def with_context context_hash
      begin
        ndc.push context_hash
        yield
      ensure
        ndc.pop
      end
    end

    # TODO: consider removing. Almost never any reason for a client to use this. Most clients should only ever be
    # calling logger.mdc.clear. NDC should almost never be cleared directly and there is little reason to clear other
    # threads. We'll leave this in here for now since the logging library we based this on provided the method, but if
    # you see this method used in a code review, make sure it is absolutely necessary.
    # Public: Convenience method that will clear both the Mapped Diagnostic Context and the Nested Diagnostic Context of
    # the current thread. If the `all` flag passed to this method is true, then the diagnostic contexts for _every_
    # thread in the application will be cleared.
    # all - Boolean flag used to clear the context of every Thread (default is false)
    def clear_diagnostic_contexts(all = false)
      if all
        MUTEX_FOR_DIAG_CLEAR.synchronize {
          Thread.list.each { |thread|
            thread[MappedDiagnosticContext::NAME].clear if thread[MappedDiagnosticContext::NAME]
            thread[NestedDiagnosticContext::NAME].clear if thread[NestedDiagnosticContext::NAME]
          }
        }
      else
        MappedDiagnosticContext.clear
        NestedDiagnosticContext.clear
      end

      self
    end

    module MappedDiagnosticContext
      extend self

      # The name used to retrieve the MDC from thread-local storage.
      NAME = 'logging.mapped-diagnostic-context'.freeze

      def []=(key, value)
        context.store(key.to_s, value)
      end

      def [](key)
        context.fetch(key.to_s, nil)
      end

      def delete(key)
        context.delete(key.to_s)
      end

      def clear
        context.clear if Thread.current[NAME]
        self
      end

      def to_s
        Logger.flatten_context context
      end

      def inherit(obj)
        case obj
          when Hash
            Thread.current[NAME] = obj.dup
          when Thread
            return if Thread.current == obj
            Mutex.new.synchronize {
              Thread.current[NAME] = obj[NAME].dup if obj[NAME]
            }
        end

        self
      end

      def context
        Thread.current[NAME] ||= Hash.new
      end
    end # MappedDiagnosticContext

    module NestedDiagnosticContext
      extend self

      NAME = 'logging.nested-diagnostic-context'.freeze

      def push(context_hash)
        # TODO: merge w/ parent context?
        new_context = peek.merge(context_hash) if peek
        new_context ||= context_hash
        context.push(new_context)
        self
      end

      alias :<< :push

      def pop
        context.pop
      end

      def peek
        context.last
      end

      def clear
        context.clear if Thread.current[NAME]
        self
      end

      def to_s
        Logger.flatten_context peek
      end

      def inherit(obj)
        case obj
          when Array
            Thread.current[NAME] = obj.dup
          when Thread
            return if Thread.current == obj
            Mutex.new.synchronize {
              Thread.current[NAME] = obj[NAME].dup if obj[NAME]
            }
        end

        self
      end

      def context
        Thread.current[NAME] ||= Array.new
      end
    end # NestedDiagnosticContext
  end
end

# :stopdoc:
# Thread hackery to inherit context. Not sure if we need it though...
class Thread
  class << self

    %w[new start fork].each do |m|
      class_eval <<-__, __FILE__, __LINE__
        alias :_orig_#{m} :#{m}
        private :_orig_#{m}
        def #{m}( *a, &b )
          create_with_logging_context(:_orig_#{m}, *a ,&b)
        end
      __
    end

    private

    # In order for the diagnostic contexts to behave properly we need to
    # inherit state from the parent thread. The only way I have found to do
    # this in Ruby is to override `new` and capture the contexts from the
    # parent Thread at the time the child Thread is created. The code below does
    # just this. If there is a more idiomatic way of accomplishing this in Ruby,
    # please let me know!
    #
    # Also, great care is taken in this code to ensure that a reference to the
    # parent thread does not exist in the binding associated with the block
    # being executed in the child thread. The same is true for the parent
    # thread's mdc and ndc. If any of those references end up in the binding,
    # then they cannot be garbage collected until the child thread exits.
    #
    def create_with_logging_context(m, *a, &b)
      mdc, ndc = nil

      if Thread.current[Woodsman::Logger::MappedDiagnosticContext::NAME]
        mdc = Thread.current[Woodsman::Logger::MappedDiagnosticContext::NAME].dup
      end

      if Thread.current[Woodsman::Logger::NestedDiagnosticContext::NAME]
        ndc = Thread.current[Woodsman::Logger::NestedDiagnosticContext::NAME].dup
      end

      self.send(m, *a) { |*args|
        Woodsman::Logger::MappedDiagnosticContext.inherit(mdc)
        Woodsman::Logger::NestedDiagnosticContext.inherit(ndc)
        b.call(*args)
      }
    end

  end
end # Thread
# :startdoc:
