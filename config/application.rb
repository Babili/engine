require File.expand_path("../boot", __FILE__)

require "rails"

require "action_view/railtie"
require "active_record/railtie"
require_relative "../lib/babili_exceptions_application"

Bundler.require(*Rails.groups)

module BabiliEngine
  class Application < Rails::Application
    config.api_only = true
    config.autoload_paths += %W(#{config.root}/lib)

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
  end
end
