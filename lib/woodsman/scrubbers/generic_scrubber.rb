module Woodsman
  module Scrubbers
    class GenericScrubber
      attr_accessor :name, :scrub_block

      def initialize(name, &scrub_block)
        @name = name
        @scrub_block = scrub_block
      end
    end
  end
end