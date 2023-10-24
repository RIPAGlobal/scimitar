FROM ruby:3.2.2

WORKDIR /app

ADD . /app

# Install nodejs
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Update bundler to correct version
RUN gem install bundler:2.4.19

# Install any needed packages
RUN bundle install
