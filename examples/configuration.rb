#!/usr/bin/env ruby
# frozen_string_literal: true

require "geminize"

# This example demonstrates two ways to configure the geminize gem:
# 1. Using environment variables
# 2. Using a configuration block

puts "Example 1: Using environment variables"
puts "--------------------------------------"
# In a real application, you would set these in your environment
ENV["GEMINI_API_KEY"] = "your-api-key-here"
ENV["GEMINI_API_VERSION"] = "v1beta"
ENV["GEMINI_DEFAULT_MODEL"] = "gemini-pro"

# The gem will automatically use these environment variables
begin
  valid = Geminize.configuration.validate!
rescue Geminize::ConfigurationError
  valid = false
end

puts "Configuration valid: #{valid}"
puts "API Key: #{Geminize.configuration.api_key}"
puts "API Version: #{Geminize.configuration.api_version}"
puts "Default Model: #{Geminize.configuration.default_model}"
puts "\n"

puts "Example 2: Using a configuration block"
puts "--------------------------------------"
# Reset the configuration to defaults (normally not needed)
# Geminize.reset_configuration

# Configure the gem using a block
Geminize.configure do |config|
  config.api_key = "your-block-configured-api-key"
  config.api_version = "v1beta"
  config.default_model = "gemini-pro-vision"
  config.timeout = 30
  config.open_timeout = 10
  config.log_requests = true
end

# Validate the configuration
begin
  valid = Geminize.configuration.validate!
rescue Geminize::ConfigurationError
  valid = false
end

puts "Configuration valid: #{valid}"
puts "API Key: #{Geminize.configuration.api_key}"
puts "API Version: #{Geminize.configuration.api_version}"
puts "Default Model: #{Geminize.configuration.default_model}"
puts "Timeout: #{Geminize.configuration.timeout} seconds"
puts "Open Timeout: #{Geminize.configuration.open_timeout} seconds"
puts "Log Requests: #{Geminize.configuration.log_requests}"
