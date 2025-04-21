# frozen_string_literal: true

# config/initializers/geminize.rb

# This is an example of how to configure the Geminize gem in a Rails application.
# Place this file in your config/initializers directory.

# Configure the Geminize gem with your API key and any other settings
Geminize.configure do |config|
  # Required settings

  # Get the API key from environment variables (recommended approach)
  # config.api_key = ENV["GEMINI_API_KEY"]

  # Or set it directly (not recommended for production)
  config.api_key = "your-api-key-here"

  # Optional settings with defaults

  # API version to use
  config.api_version = "v1beta"

  # Default model to use when not specified in requests
  config.default_model = "gemini-1.5-pro-latest"

  # Request timeout in seconds
  config.timeout = 30

  # Connection open timeout in seconds
  config.open_timeout = 10

  # Enable request logging for development/debugging
  # In production, keep this false unless debugging an issue
  config.log_requests = Rails.env.development?
end

# Optionally validate the configuration during app initialization
# This will raise Geminize::ConfigurationError if the configuration is invalid
begin
  Geminize.validate_configuration!
  Rails.logger.info "Geminize configured successfully"
rescue Geminize::ConfigurationError => e
  Rails.logger.error "Geminize configuration error: #{e.message}"
  # You might want to raise the error in development but not in production
  raise e if Rails.env.development?
end
