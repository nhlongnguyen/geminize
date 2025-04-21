# frozen_string_literal: true

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
        # This is a placeholder - will be implemented in task 6.2
        self
      end

      # Add an image to the request from raw bytes
      # @param image_bytes [String] Raw binary image data
      # @param mime_type [String] The MIME type of the image
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the image data is invalid
      def add_image_from_bytes(image_bytes, mime_type)
        # This is a placeholder - will be implemented in task 6.2
        self
      end

      # Add an image to the request from a URL
      # @param url [String] URL of the image
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the URL is invalid or the image cannot be fetched
      def add_image_from_url(url)
        # This is a placeholder - will be implemented in task 6.2
        self
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
            # Image validation will be implemented in task 6.3
          else
            raise Geminize::ValidationError.new(
              "Content part #{index} has an invalid type: #{part[:type]}",
              "INVALID_ARGUMENT"
            )
          end
        end
      end
    end
  end
end
