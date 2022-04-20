FROM ruby:2.7.6-alpine3.15

RUN apk add --update build-base tzdata git postgresql-dev yaml-dev ruby-dev \
  && rm -rf /var/cache/apk/* \
  && mkdir -p /usr/src/app \
  && addgroup -S babili \
  && adduser -S babili -G babili \
  && mkdir -p /home/babili && chown babili:babili /home/babili \
  && mkdir -p /usr/local/bundler && chown babili:babili /usr/local/bundler \
  && chown -R babili:babili /usr/local/bundle

WORKDIR /usr/src/app
USER babili

COPY Gemfile* ./
RUN bundle install

COPY . .

ARG APP_ENV=development
ENV RAILS_ENV ${APP_ENV}
ENV RACK_ENV none

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

