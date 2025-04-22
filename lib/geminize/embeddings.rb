# frozen_string_literal: true

module Geminize
  # Class for embedding generation functionality
  class Embeddings
    # Default maximum batch size
    DEFAULT_MAX_BATCH_SIZE = 100

    # @return [Geminize::Client] The client instance
    attr_reader :client

    # Initialize a new embeddings instance
    # @param client [Geminize::Client, nil] The client to use (optional)
    # @param options [Hash] Additional options
    def initialize(client = nil, options = {})
      @client = client || Client.new(options)
      @options = options
    end

    # Generate embeddings based on an embedding request
    # @param embedding_request [Geminize::Models::EmbeddingRequest] The embedding request
    # @return [Geminize::Models::EmbeddingResponse] The embedding response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate(embedding_request)
      model_name = embedding_request.model_name
      endpoint = build_embedding_endpoint(model_name)
      payload = build_embedding_request(embedding_request)

      response_data = @client.post(endpoint, payload)
      Models::EmbeddingResponse.from_hash(response_data)
    end

    # Generate embeddings from text with optional parameters
    # @param text [String, Array<String>] The input text or array of texts
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Integer] :dimensions Desired dimensionality of the embeddings
    # @option params [String] :task_type The embedding task type
    # @option params [Integer] :batch_size Maximum number of texts to process in one batch
    # @return [Geminize::Models::EmbeddingResponse] The embedding response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate_embedding(text, model_name = nil, params = {})
      # Check if we need to handle batching
      if text.is_a?(Array) && text.length > 1
        batch_size = params.delete(:batch_size) || DEFAULT_MAX_BATCH_SIZE
        if text.length > batch_size
          return batch_process_embeddings(text, model_name, params, batch_size)
        end
      end

      # Regular processing for a single text or a small batch
      embedding_request = Models::EmbeddingRequest.new(
        text,
        model_name || Geminize.configuration.default_embedding_model,
        params
      )

      generate(embedding_request)
    end

    private

    # Process multiple texts in batches
    # @param texts [Array<String>] List of texts to process
    # @param model_name [String, nil] Model name
    # @param params [Hash] Additional parameters
    # @param batch_size [Integer] Maximum batch size
    # @return [Geminize::Models::EmbeddingResponse] Combined embedding response
    def batch_process_embeddings(texts, model_name, params, batch_size)
      model = model_name || Geminize.configuration.default_embedding_model
      batches = texts.each_slice(batch_size).to_a
      responses = []

      batches.each do |batch|
        request = Models::EmbeddingRequest.new(batch, model, params)
        responses << generate(request)
      end

      # Combine all responses into a single response object
      combined_response = combine_responses(responses)
      combined_response
    end

    # Combine multiple embedding responses into a single response
    # @param responses [Array<Geminize::Models::EmbeddingResponse>] List of responses
    # @return [Geminize::Models::EmbeddingResponse] Combined response
    def combine_responses(responses)
      return responses.first if responses.length == 1

      # Create a synthesized response hash
      combined_hash = {
        "embeddings" => [],
        "usageMetadata" => {
          "promptTokenCount" => 0,
          "totalTokenCount" => 0
        }
      }

      # Merge all embeddings and usage data
      responses.each do |response|
        # Add embeddings
        if response.raw_response["embeddings"]
          combined_hash["embeddings"].concat(response.raw_response["embeddings"])
        end

        # Aggregate usage data
        if response.usage
          combined_hash["usageMetadata"]["promptTokenCount"] += response.prompt_tokens || 0
          combined_hash["usageMetadata"]["totalTokenCount"] += response.total_tokens || 0
        end
      end

      # Create a new response object
      Models::EmbeddingResponse.from_hash(combined_hash)
    end

    # Build the embedding endpoint for a specific model
    # @param model_name [String] The name of the model
    # @return [String] The complete API endpoint path for embedding generation
    def build_embedding_endpoint(model_name)
      "models/#{model_name}:embedContent"
    end

    # Build a embedding request for the Gemini API
    # @param embedding_request [Geminize::Models::EmbeddingRequest] The embedding request
    # @return [Hash] The complete request hash ready to send to the API
    def build_embedding_request(embedding_request)
      model_name = embedding_request.model_name
      Validators.validate_not_empty!(model_name, "Model name")

      embedding_request.to_hash
    end
  end
end
