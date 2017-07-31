if !Rails.env.development? && !Rails.env.test? && !ENV["SENTRY_DSN"].nil?
  require "raven"
  Raven.configure do |config|
    config.dsn          = ENV["SENTRY_DSN"]
    config.environments = %w[ qa staging production ]
  end
end
