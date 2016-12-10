module Woodsman

  # TODO: refactor
  LOG_LEVEL_DEBUG = 1
  LOG_LEVEL_INFO = 2
  LOG_LEVEL_ERROR = 4
  LOG_LEVEL_FATAL = 5

  # For standalone operation outside of Rails.
  # TODO: add timestamps and debug level like Rails logger?
  class StdOutLogger

    attr_accessor :log_level

    def initialize(log_level=LOG_LEVEL_ERROR)
      @log_level = log_level
    end

    def debug msg
      puts "#{msg}" unless @log_level > LOG_LEVEL_DEBUG
    end

    def info msg
      puts "#{msg}" unless @log_level > LOG_LEVEL_INFO
    end

    def error msg
      puts "#{msg}" unless @log_level > LOG_LEVEL_ERROR
    end

    def fatal msg
      puts "#{msg}"
    end
  end
end