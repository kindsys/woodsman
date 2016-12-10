module Woodsman
  module ConfigHandlers
    module Dummy
      # A no-op config handler for use when testing decorators
      class DummyConfigHandler
        attr_accessor :redis,:redis_url

        def fetch(key, context=nil)
          return false
        end

        def fetch_all(context=nil)
          return {}
        end

        def handles?(key)
          known_features.include?(key.to_s)
        end

        def known_features
          []
        end

        def set(key,value)
          return true
        end

        def delete(key)
          return true
        end
      end
    end
  end
end
