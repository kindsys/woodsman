module Woodsman
  module Scrubbers
    class SubstringSilencer
      attr_accessor :name, :scrub_block

      def initialize(name, search_string)
        @name = name
        @scrub_block = lambda do |line, context|
          return line.include?(search_string) ? nil : line, context
        end
      end
    end
  end
end