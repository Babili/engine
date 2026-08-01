FROM ruby:3.4.10-alpine3.24

RUN apk add --update build-base tzdata git postgresql-dev yaml-dev ruby-dev gcompat \
  && rm -rf /var/cache/apk/* \
  && mkdir -p /usr/src/app \
  && addgroup -S babili \
  && adduser -S babili -G babili \
  && mkdir -p /home/babili && chown babili:babili /home/babili \
  && mkdir -p /usr/local/bundler && chown babili:babili /usr/local/bundler \
  && chown -R babili:babili /usr/local/bundle \
  && chown -R babili:babili /usr/src/app

WORKDIR /usr/src/app
USER babili

COPY --chown=babili:babili Gemfile* ./
ARG APP_ENV=development
RUN if [ "$APP_ENV" != "development" ]; then bundle config set --local without "development test"; fi
RUN bundle install

COPY --chown=babili:babili . .

ENV RAILS_ENV=${APP_ENV}
ENV RACK_ENV=none

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

