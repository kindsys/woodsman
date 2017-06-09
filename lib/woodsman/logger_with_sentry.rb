require 'sentry-raven'

module Woodsman
  class LoggerWithSentry < Logger

    def initialize(logger, default_scrubber_stack=true, add_backtrace_cleaner=true)
      super(logger, default_scrubber_stack, add_backtrace_cleaner)
    end

    def error_exception(msg, e)
      Raven.capture_exception(e) if Raven&.configuration&.server
      msg, context = scrub("#{prefix(:error)}#{msg}#{ndc}#{mdc} exception=\"#{e}\" sentry_event_id=#{Raven&.last_event_id&.to_s} partial_backtrace=\"#{e.backtrace[0..2] * "\n"}\"")
      puts msg
      @logger.error(msg) if msg
      self
    end

    def fatal_exception(msg, e)
      Raven.capture_exception(e) if Raven&.configuration&.server
      msg, context = scrub("#{prefix(:fatal)}#{msg}#{ndc}#{mdc} exception=\"#{e}\" sentry_event_id=#{Raven&.last_event_id&.to_s} partial_backtrace=\"#{e.backtrace[0..2] * "\n"}\"")
      puts msg
      @logger.fatal(msg) if msg
      self
    end

    def prefix(log_level=:info)
      return '' unless MANDATORY_PREFIX_LOG_LEVELS.include?(log_level) || Logger.prefix
      s = ''
      # Walk caller chain until we are outside this class.
      caller.each do |c|
        s = compact_caller(c) + ' ' and break unless c =~ /logger_with_sentry.rb/
      end
      s
    end
  end
end
