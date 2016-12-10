module Woodsman
  module Scrubbers
    # Utility class for simple key value scrubbing.
    class KeyValueScrubber
      attr_accessor :name, :scrub_block

      def initialize(name, key, placeholder_value)
        @name = name
        @scrub_block = lambda do |line, context|

          if line.include? key.to_s+'=' # Optimization
            line = line.gsub /\b#{key}=\S+?(?!\S)/, "#{key}=#{placeholder_value}" #+'\1' # Handle EOL case.
            #line = line.gsub /\b#{key}=\S+?(\s)/, "#{key}=#{placeholder_value}"+'\1' # Handle general case.
          end

          # NOTE: enable in the future. Not necessary now since context is flattened into the line before scrubbing.
          #context[key.to_s] = placeholder_value if context[key.to_s]
          #context[key.to_sym] = placeholder_value if context[key.to_sym]

          return line, context
        end
      end
    end
  end
end