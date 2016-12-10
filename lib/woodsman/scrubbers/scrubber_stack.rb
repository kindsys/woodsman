module Woodsman
  module Scrubbers
    class ScrubberStack
      extend Forwardable

      attr_accessor :scrubbers
      # TODO: allow more access? maybe support all of enumerable?
      def_delegators :@scrubbers, :<<, :[], :clear, :size

      def self.default_stack
        stack = ScrubberStack.new
        # Silence good health checks by default.
        stack << Scrubbers::SubstringSilencer.new('health_check_200_silencer', 'method=GET path=/health_check format=html controller=health_check/health_check action=index status=200')
        stack << SsnScrubber.new
        stack << KeyValueScrubber.new(:email_scrubber, :email, '****')
        stack << KeyValueScrubber.new(:password_scrubber, :password, '****')
        stack << RegexLineScrubber.new(:sql_email_scrubber, /(\["email", ").*?(?="\])/i, '\1****')
        stack
      end

      def initialize
        @scrubbers = []
      end

      def names
        scrubbers.map { |s| s.name }
      end

      def scrub(line, context=nil)
        scrubbed_line, scrubbed_context = line, context # NOTE: context is not used in the current implementation.
        scrubbers.each do |scrubber|
          return scrubbed_line, scrubbed_context if scrubbed_line.nil?
          scrubbed_line, scrubbed_context = scrubber.scrub_block.call(scrubbed_line, scrubbed_context)
        end
        return scrubbed_line, scrubbed_context
      end
    end
  end
end