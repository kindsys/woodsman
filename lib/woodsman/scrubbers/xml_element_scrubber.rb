module Woodsman
  module Scrubbers
    # TODO: add an xpath scrubber?
    class XmlElementScrubber
      attr_accessor :name, :scrub_block

      def initialize(name, element_name, placeholder_value)
        @name = name
        @scrub_block = lambda do |line, context|

          if line.include? '<'+element_name.to_s #optimization
            line = line.gsub %r{<#{element_name}(.*?)>.+?</#{element_name}>}m, "<#{element_name}"+'\1'+">#{placeholder_value}</#{element_name}>"
          end

          return line, context
        end
      end
    end
  end
end