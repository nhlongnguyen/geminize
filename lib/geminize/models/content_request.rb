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
        @prompt = prompt
        @model_name = model_name || Geminize.configuration.default_model
        @temperature = params[:temperature]
        @max_tokens = params[:max_tokens]
        @top_p = params[:top_p]
        @top_k = params[:top_k]
        @stop_sequences = params[:stop_sequences]

        validate!
      end

      # Validate the request parameters
      # @raise [Geminize::ValidationError] If any parameter is invalid
      # @return [Boolean] true if all parameters are valid
      def validate!
        validate_prompt!
        validate_temperature!
        validate_max_tokens!
        validate_top_p!
        validate_top_k!
        validate_stop_sequences!
        true
      end

      # Convert the request to a hash suitable for the API
      # @return [Hash] The request as a hash
      def to_hash
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
      # @raise [Geminize::ValidationError] If the prompt is invalid
      def validate_prompt!
        Validators.validate_not_empty!(@prompt, "Prompt")
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
    end
  end
end
