module Woodsman
  module Scrubbers
    # NOTE: will scrub context with the current implementation since it is flattened into the line prior to scrubbing.
    # For the more optimized algorithm where we pre-scrub context, we'll have to update this scrubber class to touch the
    # context.
    class RegexLineScrubber
      attr_accessor :name, :scrub_block

      def initialize(name, regex, replacement)
        @name = name
        @scrub_block = lambda do |line, context|
          line = line.gsub regex, replacement
          return line, context
        end
      end
    end
  end
end