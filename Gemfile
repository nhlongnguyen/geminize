# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in geminize.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "standard", "~> 1.3"

group :test do
  gem "climate_control", "~> 1.2"
  gem "vcr"
  gem "webmock"
end

group :development, :test do
  gem "pry"
  gem "dotenv"
end
