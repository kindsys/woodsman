module Woodsman
  module Scrubbers
    class SsnScrubber < RegexLineScrubber

      def initialize
        super 'ssn_scrubber', /\d{3}\-\d{2}\-\d{4}/, 'XXX-XX-XXXX'
      end
    end
  end
end
