FROM ruby:2.6.5

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev graphviz libgeos-dev ruby-geos libjemalloc-dev libxml2-dev libxslt1-dev && \
  mkdir -p /usr/src/app && \
  groupadd -r babili && useradd -r -g babili babili && \
  mkdir -p /home/babili && chown babili:babili /home/babili && \
  chown -R babili:babili /usr/local/bundle

WORKDIR /usr/src/app
USER babili

COPY Gemfile* ./
RUN bundle install

COPY . .

ARG APP_ENV=development
ENV RAILS_ENV ${APP_ENV}
ENV RACK_ENV none

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

