Rails.application.configure do
  config.lograge.enabled               = true
  config.lograge.base_controller_class = ["ActionController::API", "ActionController::Base"]
  config.lograge.ignore_actions        = ["User::AliveController#update", "HomeController#index"]
end