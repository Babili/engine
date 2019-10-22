require File.expand_path("../boot", __FILE__)

require "rails"

require "action_view/railtie"
require "active_record/railtie"
require_relative "../lib/babili_exceptions_application"

Bundler.require(*Rails.groups)

module BabiliEngine
  class Application < Rails::Application
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

    config.load_defaults "6.0"

    # Enable per-form CSRF tokens. Previous versions had false.
    config.action_controller.per_form_csrf_tokens = false

    # Enable origin-checking CSRF mitigation. Previous versions had false.
    config.action_controller.forgery_protection_origin_check  = false
    config.action_controller.request_forgery_protection_token = false
    config.action_controller.allow_forgery_protection         = false

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Previous versions had false.
    ActiveSupport.to_time_preserves_timezone = false

    unless ENV["API_HOST"].blank?
      config.hosts += ENV["API_HOST"].split(",").map(&:strip)
    else
      config.hosts.clear()
    end
  end
end
