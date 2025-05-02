# frozen_string_literal: true

module Geminize
  class << self
    # Generate text with custom safety settings
    # @param prompt [String] The input prompt
    # @param safety_settings [Array<Hash>] Array of safety setting definitions
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with specific safety settings
    #   Geminize.generate_with_safety_settings(
    #     "Tell me a scary story",
    #     [
    #       {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
    #       {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE"}
    #     ]
    #   )
    def generate_with_safety_settings(prompt, safety_settings, model_name = nil, params = {})
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

      # Add safety settings to the request
      safety_settings.each do |setting|
        content_request.add_safety_setting(
          setting[:category],
          setting[:threshold]
        )
      end

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with maximum safety (blocks most potentially harmful content)
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with maximum safety
    #   Geminize.generate_text_safe("Tell me about conflicts", nil, temperature: 0.7)
    def generate_text_safe(prompt, model_name = nil, params = {})
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

      # Set maximum safety (block low and above)
      content_request.block_all_harmful_content

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with minimum safety (blocks only high-risk content)
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with minimum safety
    #   Geminize.generate_text_permissive("Tell me about conflicts", nil, temperature: 0.7)
    def generate_text_permissive(prompt, model_name = nil, params = {})
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

      # Set minimum safety (block only high risk)
      content_request.block_only_high_risk_content

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end
  end
end
