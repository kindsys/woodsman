module Woodsman
  module Scrubbers
    class RegexSilencer
      attr_accessor :name, :scrub_block

      def initialize(name, regex)
        @name = name
        @scrub_block = lambda do |line, context|
          return regex =~ line ? nil : line, context
        end
      end
    end
  end
end