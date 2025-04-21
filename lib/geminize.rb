# frozen_string_literal: true

require_relative 'geminize/version'
require_relative 'geminize/configuration'
require_relative 'geminize/client'

# Main module for the Geminize gem
module Geminize
  class Error < StandardError; end

  # Base error class for all Geminize errors
  class GeminizeError < Error; end

  # Error for bad requests (4xx)
  class BadRequestError < GeminizeError; end

  # Error for server errors (5xx)
  class ServerError < GeminizeError; end

  # Error for network/request issues
  class RequestError < GeminizeError; end

  class << self
    # @return [Geminize::Configuration]
    def configuration
      Configuration.instance
    end

    # Configure the gem
    # @yield [config] Configuration object that can be modified
    # @example
    #   Geminize.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_version = "v1beta"
    #     config.default_model = "gemini-1.5-pro-latest"
    #   end
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Reset the configuration to defaults
    def reset_configuration!
      configuration.reset!
    end

    # Validates the configuration
    # @return [Boolean]
    # @raise [ConfigurationError] if the configuration is invalid
    def validate_configuration!
      configuration.validate!
    end
  end
end
