# frozen_string_literal: true

module Geminize
  module Models
    # Represents a chat request to the Gemini API
    class ChatRequest
      # @return [String] The user's message content
      attr_reader :content

      # @return [String, nil] Optional user identifier
      attr_reader :user_id

      # @return [String] The model name to use
      attr_reader :model_name

      # @return [Time] When the message was created
      attr_reader :timestamp

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

      # @return [String, nil] System instruction to guide model behavior
      attr_accessor :system_instruction

      # Initialize a new chat request
      # @param content [String] The user's message content
      # @param model_name [String, nil] The model name to use
      # @param user_id [String, nil] Optional user identifier
      # @param params [Hash] Additional parameters
      # @option params [Float] :temperature Controls randomness (0.0-1.0)
      # @option params [Integer] :max_tokens Maximum tokens to generate
      # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
      # @option params [Integer] :top_k Top-k value for sampling
      # @option params [Array<String>] :stop_sequences Stop sequences to end generation
      # @option params [String] :system_instruction System instruction to guide model behavior
      def initialize(content, model_name = nil, user_id = nil, params = {})
        @content = content
        @model_name = model_name || Geminize.configuration.default_model
        @user_id = user_id
        @timestamp = Time.now
        @temperature = params[:temperature]
        @max_tokens = params[:max_tokens]
        @top_p = params[:top_p]
        @top_k = params[:top_k]
        @stop_sequences = params[:stop_sequences]
        @system_instruction = params[:system_instruction]

        validate!
      end

      # Validate the request parameters
      # @raise [Geminize::ValidationError] If any parameter is invalid
      # @return [Boolean] true if all parameters are valid
      def validate!
        validate_content!
        validate_temperature!
        validate_max_tokens!
        validate_top_p!
        validate_top_k!
        validate_stop_sequences!
        validate_system_instruction!
        true
      end

      # Convert the request to a hash for forming a single message
      # @return [Hash] A hash representation of the user message
      def to_message_hash
        {
          role: "user",
          parts: [
            {
              text: @content
            }
          ]
        }
      end

      # Convert the request to a hash suitable for the API
      # @param history [Array<Hash>] Previous messages in the conversation
      # @return [Hash] The request as a hash
      def to_hash(history = [])
        request = {
          contents: history + [to_message_hash],
          generationConfig: generation_config
        }.compact

        # Add system_instruction if provided
        if @system_instruction
          request[:systemInstruction] = {
            parts: [
              {
                text: @system_instruction
              }
            ]
          }
        end

        request
      end

      # Alias for to_hash for consistency with Ruby conventions
      # @param history [Array<Hash>] Previous messages in the conversation
      # @return [Hash] The request as a hash
      def to_h(history = [])
        to_hash(history)
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

      # Validate the content parameter
      # @raise [Geminize::ValidationError] If the content is invalid
      def validate_content!
        Validators.validate_not_empty!(@content, "Content")
      end

      # Validate the system_instruction parameter
      # @raise [Geminize::ValidationError] If the system_instruction is invalid
      def validate_system_instruction!
        return if @system_instruction.nil?

        unless @system_instruction.is_a?(String)
          raise Geminize::ValidationError.new("System instruction must be a string", "INVALID_ARGUMENT")
        end

        if @system_instruction.empty?
          raise Geminize::ValidationError.new("System instruction cannot be empty", "INVALID_ARGUMENT")
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
    end
  end
end
