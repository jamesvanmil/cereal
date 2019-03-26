FROM ruby:2.3

## Update and install software
RUN apt-get update && apt-get install -y \ 
  build-essential sqlite3 vim

RUN mkdir -p /app 
WORKDIR /app

## Install ruby stuff
COPY Gemfile ./ 
RUN gem install bundler && bundle install --jobs 20 --retry 5

## Build the database
COPY cereal_db_creation ./
COPY *.csv ./
RUN ./cereal_db_creation

COPY . ./
