if !Rails.env.development? && !Rails.env.test? && !ENV["SENTRY_DSN"].nil?
  Sentry.init do |config|
    config.dsn                  = ENV["SENTRY_DSN"]
    config.enabled_environments = %w[ qa staging production ]
    config.send_default_pii     = true
  end
end
