require_relative "boot"

require "rails"

require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

require_relative "../lib/babili_exceptions_application"
require_relative "../lib/babili_logger"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BabiliEngine
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.api_only = true

    config.exceptions_app = BabiliExceptionsApplication.call
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*",
          headers:     :any,
          methods:     [:get, :post, :delete, :put, :options],
          credentials: false
      end
    end

    # Log formatter
    config.logger    = BabiliLogger.logger

    # Enable per-form CSRF tokens. Previous versions had false.
    config.action_controller.per_form_csrf_tokens = false

    # Enable origin-checking CSRF mitigation. Previous versions had false.
    config.action_controller.forgery_protection_origin_check  = false
    config.action_controller.request_forgery_protection_token = false
    config.action_controller.allow_forgery_protection         = false

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Previous versions had false.
    ActiveSupport.to_time_preserves_timezone = false

    # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
    if ENV["ENABLE_HSTS"] == "true"
      config.force_ssl   = true 
      config.ssl_options = { redirect: false }
    end

    unless ENV["API_HOST"].blank?
      config.hosts += ENV["API_HOST"].split(",").map(&:strip)
    else
      config.hosts.clear()
    end
  end
end
