FROM ruby:2.4

# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libcurl4-openssl-dev file patch

COPY Gemfile* ./
RUN bundle install

COPY . .

ARG APP_ENV=development
ENV RAILS_ENV ${APP_ENV}
ENV RACK_ENV none

CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.rb"]
# CMD ["bundle", "exec", "unicorn", "-c", "config/unicorn.rb"]
