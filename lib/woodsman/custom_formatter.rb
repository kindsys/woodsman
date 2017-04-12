module Woodsman
  class CustomFormatter < ::Logger::Formatter

    def call(severity, timestamp, progname, msg)
      "#{String === msg ? msg : msg.inspect}\n"
    end
  end
end