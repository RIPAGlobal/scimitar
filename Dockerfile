FROM ruby:3.3.0

WORKDIR /app

ADD . /app

# Install nodejs
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client \
        && apt-get clean

# Update RubyGems to avoid Psych 4-vs-5 bugs for native extension builds:
# https://github.com/ruby/psych/discussions/607#discussioncomment-7233953
RUN gem update --system

# Update bundler to correct version
RUN gem install bundler:2.4.22

# Install any needed packages
RUN bundle install
