FROM ruby:2.4 AS databasebuilder
RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
ENV ENV=production RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1
COPY . .
RUN rake db:drop && rake db:setup

FROM ruby:2.4
RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
ENV ENV=production RAILS_ENV=production
COPY . .
COPY --from=databasebuilder /usr/src/app/db/production.sqlite3 ./db/production.sqlite3
CMD bundle exec puma -p 3000 -e production -w $(nproc) -C "-"
EXPOSE 3000
