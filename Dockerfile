FROM ruby:3.2.0

WORKDIR /app

ADD . /app

# Install nodejs
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# Update bundler to correct version
RUN gem install bundler:2.4.19

# Install any needed packages
RUN bundle install

# Use port 4000 (change this if oZone ever uses it)
EXPOSE 4000
