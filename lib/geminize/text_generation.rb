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

    # Generate content with both text and images
    # @param prompt [String] The input prompt text
    # @param images [Array<Hash>] Array of image data hashes
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option images [Hash] :source_type Source type for image ('file', 'bytes', or 'url')
    # @option images [String] :data File path, raw bytes, or URL depending on source_type
    # @option images [String] :mime_type MIME type for the image (optional for file and url)
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate with an image file
    #   generate_multimodal("Describe this image", [{source_type: 'file', data: 'path/to/image.jpg'}])
    # @example Generate with multiple images
    #   generate_multimodal("Compare these images", [
    #     {source_type: 'file', data: 'path/to/image1.jpg'},
    #     {source_type: 'url', data: 'https://example.com/image2.jpg'}
    #   ])
    def generate_multimodal(prompt, images, model_name = nil, params = {})
      # Create a new content request with the prompt text
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || Geminize.configuration.default_model,
        params
      )

      # Add each image to the request based on its source type
      images.each do |image|
        case image[:source_type]
        when "file"
          content_request.add_image_from_file(image[:data])
        when "bytes"
          content_request.add_image_from_bytes(image[:data], image[:mime_type])
        when "url"
          content_request.add_image_from_url(image[:data])
        else
          raise Geminize::ValidationError.new(
            "Invalid image source type: #{image[:source_type]}. Must be 'file', 'bytes', or 'url'",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Generate content with the constructed multimodal request
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
