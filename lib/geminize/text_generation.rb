# frozen_string_literal: true

module Geminize
  # Class for text generation functionality
  class TextGeneration
    # @return [Geminize::Client] The client instance
    attr_reader :client

    # Initialize a new text generation instance
    # @param client [Geminize::Client, nil] The client to use (optional)
    # @param options [Hash] Additional options
    def initialize(client = nil, options = {})
      @client = client || Client.new(options)
      @options = options
    end

    # Generate text based on a content request
    # @param content_request [Geminize::Models::ContentRequest] The content request
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate(content_request)
      model_name = content_request.model_name
      endpoint = RequestBuilder.build_text_generation_endpoint(model_name)
      payload = RequestBuilder.build_text_generation_request(content_request)

      response_data = @client.post(endpoint, payload)
      Models::ContentResponse.from_hash(response_data)
    end

    # Generate text from a prompt string with optional parameters
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate_text(prompt, model_name = nil, params = {})
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || Geminize.configuration.default_model,
        params
      )

      generate(content_request)
    end

    # Generate text with retries for transient errors
    # @param content_request [Geminize::Models::ContentRequest] The content request
    # @param max_retries [Integer] Maximum number of retry attempts
    # @param retry_delay [Float] Delay between retries in seconds
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If all retry attempts fail
    def generate_with_retries(content_request, max_retries = 3, retry_delay = 1.0)
      retries = 0

      begin
        generate(content_request)
      rescue Geminize::RateLimitError, Geminize::ServerError => e
        if retries < max_retries
          retries += 1
          sleep retry_delay * retries # Exponential backoff
          retry
        else
          raise e
        end
      end
    end
  end
end
