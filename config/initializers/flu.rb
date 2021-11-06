Flu.configure do |config|
  config.development_environments  = ["test"]
  config.rabbitmq_host             = ENV["RABBITMQ_HOST"]
  config.rabbitmq_port             = ENV["RABBITMQ_PORT"]&.to_i
  config.rabbitmq_user             = ENV["RABBITMQ_USER"]
  config.rabbitmq_password         = ENV["RABBITMQ_PASSWORD"]
  config.rabbitmq_exchange_name    = ENV["RABBITMQ_EXCHANGE_NAME"]
  config.rabbitmq_exchange_durable = ENV["RABBITMQ_EXCHANGE_DURABLE"] == "true"
  config.auto_connect_to_exchange  = ENV["DISABLE_FLU_AUTO_CONNECT"] != "true"
  config.logger                    = Rails.logger
  config.application_name          = "BabiliEngine"
end
