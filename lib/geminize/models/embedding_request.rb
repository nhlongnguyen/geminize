# frozen_string_literal: true

module Geminize
  module Models
    # Represents a request for embedding generation from the Gemini API
    class EmbeddingRequest
      attr_reader :text, :model_name, :task_type, :dimensions, :title

      # Supported task types for embeddings
      TASK_TYPES = [
        "RETRIEVAL_QUERY",    # For embedding queries for retrieval
        "RETRIEVAL_DOCUMENT", # For embedding documents for retrieval
        "SEMANTIC_SIMILARITY", # For embeddings that will be compared for similarity
        "CLASSIFICATION",     # For embeddings that will be used for classification
        "CLUSTERING"          # For embeddings that will be clustered
      ].freeze

      # Initialize a new embedding request
      # @param model_name [String] The model name to use
      # @param text [String, Array<String>] The input text(s) to embed
      # @param task_type [String] The embedding task type
      # @param params [Hash] Additional parameters
      # @option params [Integer] :dimensions Desired dimensionality of the embeddings
      # @option params [String] :title Optional title for the request
      def initialize(text = nil, model_name = nil, **options)
        # Support both old positional params and new named params
        if text.nil? && model_name.nil?
          # New named parameters style
          @model_name = options.delete(:model_name)
          @text = options.delete(:text)
        else
          # Old positional parameters style
          @text = text
          @model_name = model_name
        end

        @task_type = options[:task_type] || "RETRIEVAL_DOCUMENT"
        @dimensions = options[:dimensions]
        @title = options[:title]

        validate!
      end

      # Get the request as a hash
      # @return [Hash] The request hash
      def to_hash
        if batch?
          build_batch_request
        else
          build_single_request
        end
      end

      # Alias for to_hash
      def to_h
        to_hash
      end

      # Check if this request contains multiple texts
      # @return [Boolean] True if the request contains multiple texts
      def batch?
        @text.is_a?(Array)
      end

      # Alias for batch?
      alias_method :multiple?, :batch?

      # Create a single request hash for the given text
      # @param text_input [String] The text to create a request for
      # @return [Hash] The request hash for a single text
      def single_request_hash(text_input)
        request = {
          model: @model_name,
          content: {
            parts: [
              {
                text: text_input.to_s
              }
            ]
          },
          taskType: @task_type
        }

        # Add title if provided
        request[:content][:title] = @title if @title

        # Add optional parameters if they exist
        request[:dimensions] = @dimensions if @dimensions

        request
      end

      private

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

      # Create a single request hash
      # @return [Hash] The request hash for a single text
      def build_single_request
        request = {
          model: @model_name,
          content: {
            parts: [
              {
                text: @text.to_s
              }
            ]
          },
          taskType: @task_type
        }

        # Add title if provided
        request[:content][:title] = @title if @title

        # Add optional parameters if they exist
        request[:dimensions] = @dimensions if @dimensions

        request
      end

      # Create a batch request hash
      # @return [Hash] The request hash for a batch of texts
      def build_batch_request
        {
          requests: @text.map do |text_item|
            {
              model: "models/#{@model_name}",
              content: {
                parts: [
                  {
                    text: text_item
                  }
                ]
              },
              taskType: @task_type
            }
          end
        }
      end
    end
  end
end
