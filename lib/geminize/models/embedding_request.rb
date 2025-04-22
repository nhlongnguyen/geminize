# frozen_string_literal: true

module Geminize
  module Models
    # Represents a request for embedding generation from the Gemini API
    class EmbeddingRequest
      # @return [String, Array<String>] The input text(s) to embed
      attr_reader :text

      # @return [String] The model name to use
      attr_reader :model_name

      # @return [String, nil] Optional title for the request
      attr_reader :title

      # @return [Integer, nil] The desired dimensionality of the embeddings
      attr_accessor :dimensions

      # @return [String] The embedding task type (default: 'RETRIEVAL_DOCUMENT')
      attr_accessor :task_type

      # Supported task types for embeddings
      TASK_TYPES = [
        "RETRIEVAL_QUERY",    # For embedding queries for retrieval
        "RETRIEVAL_DOCUMENT", # For embedding documents for retrieval
        "SEMANTIC_SIMILARITY", # For embeddings that will be compared for similarity
        "CLASSIFICATION",     # For embeddings that will be used for classification
        "CLUSTERING"          # For embeddings that will be clustered
      ].freeze

      # Initialize a new embedding request
      # @param text [String, Array<String>] The input text(s) to embed
      # @param model_name [String] The model name to use
      # @param params [Hash] Additional parameters
      # @option params [Integer] :dimensions Desired dimensionality of the embeddings
      # @option params [String] :task_type The embedding task type
      # @option params [String] :title Optional title for the request
      def initialize(text, model_name = nil, params = {})
        @text = text
        @model_name = model_name || Geminize.configuration.default_embedding_model
        @dimensions = params[:dimensions]
        @task_type = params[:task_type] || "RETRIEVAL_DOCUMENT"
        @title = params[:title]

        validate!
      end

      # Convert the request to a hash for the API
      # @return [Hash] The request hash
      def to_hash
        request = {
          content: {
            parts: texts_to_parts
          }
        }

        # Add title if provided
        request[:content][:title] = @title if @title

        # Add optional parameters if they exist
        request[:dimensions] = @dimensions if @dimensions
        request[:taskType] = @task_type if @task_type

        request
      end

      # Alias for to_hash
      # @return [Hash] The request hash
      def to_h
        to_hash
      end

      # Check if this request contains multiple texts
      # @return [Boolean] True if the request contains multiple texts
      def multiple?
        @text.is_a?(Array)
      end

      # Check if this request is for a batch of texts
      # @return [Boolean] True if multiple texts
      def batch?
        multiple?
      end

      private

      # Convert texts to API-compatible parts format
      # @return [Array<Hash>] Array of text parts
      def texts_to_parts
        if @text.is_a?(Array)
          @text.map { |t| {text: t.to_s} }
        else
          [{text: @text.to_s}]
        end
      end

      # Validate the request parameters
      # @raise [Geminize::ValidationError] If any parameter is invalid
      # @return [Boolean] true if all parameters are valid
      def validate!
        validate_text!
        validate_model_name!
        validate_dimensions!
        validate_task_type!
        true
      end

      # Validate input text
      # @raise [Geminize::ValidationError] If text is invalid
      def validate_text!
        if @text.nil?
          raise Geminize::ValidationError.new("text cannot be nil", "INVALID_ARGUMENT")
        end

        if @text.is_a?(Array)
          if @text.empty?
            raise Geminize::ValidationError.new("Text array cannot be empty", "INVALID_ARGUMENT")
          end

          @text.each_with_index do |t, index|
            if t.nil? || (t.is_a?(String) && t.empty?)
              raise Geminize::ValidationError.new("Text at index #{index} cannot be nil or empty", "INVALID_ARGUMENT")
            end
          end
        elsif @text.is_a?(String) && @text.empty?
          raise Geminize::ValidationError.new("Text cannot be empty", "INVALID_ARGUMENT")
        end
      end

      # Validate the model name
      # @raise [Geminize::ValidationError] If model name is invalid
      def validate_model_name!
        if @model_name.nil?
          raise Geminize::ValidationError.new("model_name cannot be nil", "INVALID_ARGUMENT")
        end

        if @model_name.is_a?(String) && @model_name.empty?
          raise Geminize::ValidationError.new("Model name cannot be empty", "INVALID_ARGUMENT")
        end
      end

      # Validate dimensions if provided
      # @raise [Geminize::ValidationError] If dimensions are invalid
      def validate_dimensions!
        return if @dimensions.nil?

        Validators.validate_positive_integer!(@dimensions, "Dimensions")
      end

      # Validate task type if provided
      # @raise [Geminize::ValidationError] If task type is invalid
      def validate_task_type!
        return if @task_type.nil?

        unless TASK_TYPES.include?(@task_type)
          task_types_str = TASK_TYPES.map { |t| "\"#{t}\"" }.join(", ")
          raise Geminize::ValidationError.new(
            "task_type must be one of: #{task_types_str}",
            "INVALID_ARGUMENT"
          )
        end
      end
    end
  end
end
