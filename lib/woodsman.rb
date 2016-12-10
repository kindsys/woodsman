require 'require_all'
require_rel 'woodsman'

module Woodsman
  class << self
    def logger
      @@logger
    end

    def logger= logger
      @@logger = logger
    end

    def retryable(opts=nil, &block)
      if opts
        max_retries = opts[:max_retries]
        retry_delay = opts[:retry_delay]
        retry_on_error = opts[:retry_on_error]
        retry_lambda = opts[:retry_lambda]
      end

      max_retries ||= 3
      retry_delay ||= 0.05
      retry_on_error ||= true

      retry_metadata = {try_number: 0, error_count: 0}
      ret = nil
      begin
        begin
          retry_metadata[:try_number] += 1
          try_again = false
          ret = yield(retry_metadata)
          try_again = retry_lambda.call(ret) if retry_lambda
        rescue => e
          retry_metadata[:error_count] += 1
          try_again = true if retry_on_error
          try_again ||= retry_lambda.call(e) if retry_lambda
          sleep retry_delay and retry if try_again and retry_metadata[:try_number] <= max_retries
          raise
        end
        sleep retry_delay if try_again and retry_metadata[:try_number] <= max_retries
      end while try_again and retry_metadata[:try_number] <= max_retries
      ret
    end

    def truthy?(val)
      !!val.to_s.match(/(true|t|yes|y|1)$/i)
    end

    def valid_uid?(val)
      !!val.to_s.match(/^\h{8}-(?:\h{4}-){3}\h{12}$/i)
    end

    private
    @@logger = Logger.new(StdOutLogger.new)
  end
end
