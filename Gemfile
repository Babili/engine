source "http://rubygems.org"

gem "rails",               "6.0.0"
gem "pg",                  "1.1.4"
gem "jwt",                 "2.2.1"
gem "sentry-raven",        "2.12.0"
gem "sidekiq",             "6.0.2"
gem "sidekiq-unique-jobs", "6.0.15"
gem "awesome_print",       "1.8.0"
gem "rest-client",         "2.1.0"
gem "puma",                "4.3.3"
gem "flu-rails",           git: "https://github.com/crepesourcing/flu-rails.git"
gem "rack-cors",           "1.0.3", require: "rack/cors"

gem "byebug"

group :development do
  gem "annotate", git: "https://github.com/ctran/annotate_models.git", branch: "develop"
end

group :development, :test do
  gem "rspec-rails",      "3.9.0"
  gem "database_cleaner", "1.7.0"
end