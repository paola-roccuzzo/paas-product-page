FROM ruby:2.3.3-alpine

ENV RUNTIME_PACKAGES "git nodejs"
ENV DEV_PACKAGES "gcc ruby-dev make g++ zlib-dev libffi-dev"
COPY bower.json /tmp/bower.json
COPY Gemfile /tmp/Gemfile
COPY Gemfile.lock /tmp/Gemfile.lock
RUN apk add --update $RUNTIME_PACKAGES
RUN apk add $DEV_PACKAGES \
  && npm install -g bower \
  && gem install bundle --no-document \
  && cd /tmp && bundle \
  && apk del $DEV_PACKAGES \
  && rm -rf /var/cache/apk/*
