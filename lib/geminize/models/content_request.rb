# frozen_string_literal: true

require "base64"
require "mime/types"
require "open-uri"

module Geminize
  module Models
    # Represents a request for text generation from the Gemini API
    class ContentRequest
      # Gemini API generation parameters
      # @return [String] The input prompt text
      attr_reader :prompt

      # @return [String] The model name to use
      attr_reader :model_name

      # @return [Float] Temperature (controls randomness)
      attr_accessor :temperature

      # @return [Integer] Maximum tokens to generate
      attr_accessor :max_tokens

      # @return [Float] Top-p value for nucleus sampling
      attr_accessor :top_p

      # @return [Integer] Top-k value for sampling
      attr_accessor :top_k

      # @return [Array<String>] Stop sequences to end generation
      attr_accessor :stop_sequences

      # @return [Array<Hash>] Content parts for multimodal input
      attr_reader :content_parts

      # Supported image MIME types
      SUPPORTED_IMAGE_MIME_TYPES = [
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp"
      ].freeze

      # Initialize a new content generation request
      # @param prompt [String] The input prompt text
      # @param model_name [String] The model name to use
      # @param params [Hash] Additional parameters
      # @option params [Float] :temperature Controls randomness (0.0-1.0)
      # @option params [Integer] :max_tokens Maximum tokens to generate
      # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
      # @option params [Integer] :top_k Top-k value for sampling
      # @option params [Array<String>] :stop_sequences Stop sequences to end generation
      def initialize(prompt, model_name = nil, params = {})
        # Validate prompt first, before even trying to use it
        validate_prompt!(prompt)

        @prompt = prompt
        @model_name = model_name || Geminize.configuration.default_model
        @temperature = params[:temperature]
        @max_tokens = params[:max_tokens]
        @top_p = params[:top_p]
        @top_k = params[:top_k]
        @stop_sequences = params[:stop_sequences]

        # Initialize content parts with the prompt as the first text part
        @content_parts = []
        add_text(prompt)

        validate!
      end

      # Add text content to the request
      # @param text [String] The text to add
      # @return [self] The request object for chaining
      def add_text(text)
        Validators.validate_not_empty!(text, "Text content")
        @content_parts << { type: "text", text: text }
        self
      end

      # Add an image to the request from a file path
      # @param file_path [String] Path to the image file
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the file is invalid or not found
      def add_image_from_file(file_path)
        unless File.exist?(file_path)
          raise Geminize::ValidationError.new(
            "Image file not found: #{file_path}",
            "INVALID_ARGUMENT"
          )
        end

        unless File.file?(file_path)
          raise Geminize::ValidationError.new(
            "Path is not a file: #{file_path}",
            "INVALID_ARGUMENT"
          )
        end

        begin
          image_data = File.binread(file_path)
          mime_type = detect_mime_type(file_path)
          add_image_from_bytes(image_data, mime_type)
        rescue => e
          raise Geminize::ValidationError.new(
            "Error reading image file: #{e.message}",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Add an image to the request from raw bytes
      # @param image_bytes [String] Raw binary image data
      # @param mime_type [String] The MIME type of the image
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the image data is invalid
      def add_image_from_bytes(image_bytes, mime_type)
        validate_image_bytes!(image_bytes)
        validate_mime_type!(mime_type)

        # Encode the image as base64
        base64_data = Base64.strict_encode64(image_bytes)

        @content_parts << {
          type: "image",
          mime_type: mime_type,
          data: base64_data
        }

        self
      end

      # Add an image to the request from a URL
      # @param url [String] URL of the image
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the URL is invalid or the image cannot be fetched
      def add_image_from_url(url)
        validate_url!(url)

        begin
          # Open the URL and read the binary data
          uri_object = URI.open(url, "rb")
          image_data = uri_object.read
          uri_object.close if uri_object.respond_to?(:close)

          # Try to detect MIME type from URL extension, fallback to jpeg if can't detect
          mime_type = detect_mime_type_from_url(url) || "image/jpeg"

          add_image_from_bytes(image_data, mime_type)
        rescue OpenURI::HTTPError => e
          raise Geminize::ValidationError.new(
            "Error fetching image from URL: HTTP error #{e.message}",
            "INVALID_ARGUMENT"
          )
        rescue => e
          raise Geminize::ValidationError.new(
            "Error fetching image from URL: #{e.message}",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Check if this request has multimodal content
      # @return [Boolean] True if the request contains multiple content types
      def multimodal?
        return false if @content_parts.empty?

        # Check if we have any non-text parts or multiple text parts
        @content_parts.any? { |part| part[:type] != "text" } || @content_parts.count > 1
      end

      # Validate the request parameters
      # @raise [Geminize::ValidationError] If any parameter is invalid
      # @return [Boolean] true if all parameters are valid
      def validate!
        validate_temperature!
        validate_max_tokens!
        validate_top_p!
        validate_top_k!
        validate_stop_sequences!
        validate_content_parts!
        true
      end

      # Convert the request to a hash suitable for the API
      # @return [Hash] The request as a hash
      def to_hash
        if multimodal?
          {
            contents: [
              {
                parts: @content_parts
              }
            ],
            generationConfig: generation_config
          }.compact
        else
          # Keep backward compatibility for text-only requests
          {
            contents: [
              {
                parts: [
                  {
                    text: @prompt
                  }
                ]
              }
            ],
            generationConfig: generation_config
          }.compact
        end
      end

      # Alias for to_hash for consistency with Ruby conventions
      # @return [Hash] The request as a hash
      def to_h
        to_hash
      end

      private

      # Build the generation configuration hash
      # @return [Hash] The generation configuration
      def generation_config
        config = {}
        config[:temperature] = @temperature if @temperature
        config[:maxOutputTokens] = @max_tokens if @max_tokens
        config[:topP] = @top_p if @top_p
        config[:topK] = @top_k if @top_k
        config[:stopSequences] = @stop_sequences if @stop_sequences && !@stop_sequences.empty?

        config.empty? ? nil : config
      end

      # Validate the prompt parameter
      # @param prompt_text [String] The prompt text to validate
      # @raise [Geminize::ValidationError] If the prompt is invalid
      def validate_prompt!(prompt_text = @prompt)
        if prompt_text.nil?
          raise Geminize::ValidationError.new("Prompt cannot be nil", "INVALID_ARGUMENT")
        end

        unless prompt_text.is_a?(String)
          raise Geminize::ValidationError.new("Prompt must be a string", "INVALID_ARGUMENT")
        end

        if prompt_text.empty?
          raise Geminize::ValidationError.new("Prompt cannot be empty", "INVALID_ARGUMENT")
        end
      end

      # Validate the temperature parameter
      # @raise [Geminize::ValidationError] If the temperature is invalid
      def validate_temperature!
        Validators.validate_probability!(@temperature, "Temperature")
      end

      # Validate the max_tokens parameter
      # @raise [Geminize::ValidationError] If the max_tokens is invalid
      def validate_max_tokens!
        Validators.validate_positive_integer!(@max_tokens, "Max tokens")
      end

      # Validate the top_p parameter
      # @raise [Geminize::ValidationError] If the top_p is invalid
      def validate_top_p!
        Validators.validate_probability!(@top_p, "Top-p")
      end

      # Validate the top_k parameter
      # @raise [Geminize::ValidationError] If the top_k is invalid
      def validate_top_k!
        Validators.validate_positive_integer!(@top_k, "Top-k")
      end

      # Validate the stop_sequences parameter
      # @raise [Geminize::ValidationError] If the stop_sequences is invalid
      def validate_stop_sequences!
        Validators.validate_string_array!(@stop_sequences, "Stop sequences")
      end

      # Validate the content_parts
      # @raise [Geminize::ValidationError] If any content part is invalid
      def validate_content_parts!
        return if @content_parts.empty?

        @content_parts.each_with_index do |part, index|
          unless part.is_a?(Hash) && part[:type]
            raise Geminize::ValidationError.new(
              "Content part #{index} must be a hash with a :type key",
              "INVALID_ARGUMENT"
            )
          end

          case part[:type]
          when "text"
            Validators.validate_not_empty!(part[:text], "Text content for part #{index}")
          when "image"
            validate_image_part!(part, index)
          else
            raise Geminize::ValidationError.new(
              "Content part #{index} has an invalid type: #{part[:type]}",
              "INVALID_ARGUMENT"
            )
          end
        end
      end

      # Validate an image part
      # @param part [Hash] The image part to validate
      # @param index [Integer] The index of the part in the content_parts array
      # @raise [Geminize::ValidationError] If the image part is invalid
      def validate_image_part!(part, index)
        unless part[:mime_type]
          raise Geminize::ValidationError.new(
            "Image part #{index} is missing mime_type",
            "INVALID_ARGUMENT"
          )
        end

        unless part[:data]
          raise Geminize::ValidationError.new(
            "Image part #{index} is missing data",
            "INVALID_ARGUMENT"
          )
        end

        validate_mime_type!(part[:mime_type], "Image part #{index} mime_type")
      end

      # Validate image bytes
      # @param image_bytes [String] The image bytes to validate
      # @raise [Geminize::ValidationError] If the image bytes are invalid
      def validate_image_bytes!(image_bytes)
        if image_bytes.nil?
          raise Geminize::ValidationError.new(
            "Image data cannot be nil",
            "INVALID_ARGUMENT"
          )
        end

        unless image_bytes.is_a?(String)
          raise Geminize::ValidationError.new(
            "Image data must be a binary string",
            "INVALID_ARGUMENT"
          )
        end

        if image_bytes.empty?
          raise Geminize::ValidationError.new(
            "Image data cannot be empty",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate a MIME type
      # @param mime_type [String] The MIME type to validate
      # @param name [String] The name of the parameter for error messages
      # @raise [Geminize::ValidationError] If the MIME type is invalid
      def validate_mime_type!(mime_type, name = "MIME type")
        Validators.validate_not_empty!(mime_type, name)

        unless SUPPORTED_IMAGE_MIME_TYPES.include?(mime_type)
          raise Geminize::ValidationError.new(
            "#{name} must be one of: #{SUPPORTED_IMAGE_MIME_TYPES.join(", ")}",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate a URL
      # @param url [String] The URL to validate
      # @raise [Geminize::ValidationError] If the URL is invalid
      def validate_url!(url)
        Validators.validate_not_empty!(url, "URL")

        # Simple URL validation
        unless url =~ %r{\A(http|https)://}
          raise Geminize::ValidationError.new(
            "URL must start with http:// or https://",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Detect MIME type from file path
      # @param file_path [String] The file path
      # @return [String] The detected MIME type
      # @raise [Geminize::ValidationError] If the MIME type is not supported
      def detect_mime_type(file_path)
        types = MIME::Types.type_for(file_path)
        mime_type = types.first&.content_type if types.any?

        # If we couldn't detect MIME type or it's not supported, raise an error
        unless mime_type && SUPPORTED_IMAGE_MIME_TYPES.include?(mime_type)
          raise Geminize::ValidationError.new(
            "Unsupported image format. Supported formats: #{SUPPORTED_IMAGE_MIME_TYPES.join(", ")}",
            "INVALID_ARGUMENT"
          )
        end

        mime_type
      end

      # Detect MIME type from URL
      # @param url [String] The URL
      # @return [String, nil] The detected MIME type or nil if not detected
      def detect_mime_type_from_url(url)
        # Extract file extension from URL
        extension = File.extname(url).downcase
        return nil if extension.empty?

        # Remove the leading dot
        extension = extension[1..]

        # Map extensions to MIME types
        case extension
        when "jpg", "jpeg"
          "image/jpeg"
        when "png"
          "image/png"
        when "gif"
          "image/gif"
        when "webp"
          "image/webp"
        else
          nil
        end
      end
    end
  end
end
