require "logger"
require "active_support"

module BabiliLogger
  class LogFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      formatted_time    = time&.utc&.iso8601
      level             = severity&.upcase&.ljust(5, " ")
      application_name  = LogFormatter.application_name
      environment       = LogFormatter.environment_name
      thread_id         = Thread.current&.object_id
      context           = progname
      "[#{formatted_time}] [#{level}] [#{application_name}] [#{environment}] [#{thread_id}] [#{context}] [] #{msg}\n"
    end

    def self.application_name
      @application_name ||= ENV["LOGGER_APPLICATION_NAME"] || "event-store"
    end

    def self.environment_name
      @environment_name ||= ENV["LOGGER_ENVIRONMENT_NAME"] || "development"
    end
  end

  def self.logger
    @logger ||= BabiliLogger.create_logger
  end

  def self.create_logger
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = LogFormatter.new
    logger
  end
end

