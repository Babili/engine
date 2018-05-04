source "http://rubygems.org"

gem "pg",                  "0.21.0"
gem "jwt",                 "2.1.0"
gem "rails",               "5.1.5"
gem "sentry-raven",        "2.7.2"
gem "sidekiq",             "5.1.1"
gem "awesome_print",       "1.8.0"
gem "rest-client",         "2.0.2"
gem "unicorn",             "5.4.0"
gem "flu-rails",           git: "https://github.com/crepesourcing/flu-rails.git"
gem "sidekiq-unique-jobs", "5.0.10"
gem "rack-cors",           "1.0.2", require: "rack/cors"

gem "byebug"

group :development do
  gem "annotate", git: "https://github.com/ctran/annotate_models.git", branch: "develop"
end

group :development, :test do
  gem "rspec-rails",      "3.7.2"
  gem "database_cleaner", "1.6.2"
end
