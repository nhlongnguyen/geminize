# frozen_string_literal: true

require_relative "geminize/version"
require_relative "geminize/errors"
require_relative "geminize/configuration"
require_relative "geminize/validators"
require_relative "geminize/error_parser"
require_relative "geminize/error_mapper"
require_relative "geminize/middleware/error_handler"
require_relative "geminize/client"
require_relative "geminize/models/content_request"
require_relative "geminize/models/content_response"
require_relative "geminize/request_builder"
require_relative "geminize/text_generation"

# Main module for the Geminize gem
module Geminize
  class Error < StandardError; end

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

    # Generate text from a prompt using the Gemini API
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate_text(prompt, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator and content request
      generator = TextGeneration.new(nil, client_options)
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end
  end
end
