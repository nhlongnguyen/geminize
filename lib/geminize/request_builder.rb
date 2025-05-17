# frozen_string_literal: true

module Geminize
  # Utility module for building requests to the Gemini API
  module RequestBuilder
    class << self
      # Build a text generation request for the Gemini API
      # @param content_request [Geminize::Models::ContentRequest] The content request
      # @return [Hash] The complete request hash ready to send to the API
      def build_text_generation_request(content_request)
        model_name = content_request.model_name
        Validators.validate_not_empty!(model_name, "Model name")

        {
          model: model_name,
          **content_request.to_hash
        }
      end

      # Build a chat request for the Gemini API
      # @param chat_request [Geminize::Models::ChatRequest] The chat request
      # @param message_history [Array<Hash>] The message history from the conversation
      # @return [Hash] The complete request hash ready to send to the API
      def build_chat_request(chat_request, message_history = [])
        model_name = chat_request.model_name
        Validators.validate_not_empty!(model_name, "Model name")

        {
          model: model_name,
          **chat_request.to_hash(message_history)
        }
      end

      # Build a complete API endpoint path for a model
      # @param model_name [String] The name of the model
      # @param action [String] The action to perform (e.g., "generateContent")
      # @return [String] The complete API endpoint path
      def build_model_endpoint(model_name, action)
        "models/#{model_name}:#{action}"
      end

      # Build the text generation endpoint for a specific model
      # @param model_name [String] The name of the model
      # @return [String] The complete API endpoint path for text generation
      def build_text_generation_endpoint(model_name)
        build_model_endpoint(model_name, "generateContent")
      end

      # Build the streaming text generation endpoint for a specific model
      # @param model_name [String] The name of the model
      # @return [String] The complete API endpoint path for streaming text generation
      def build_streaming_endpoint(model_name)
        build_model_endpoint(model_name, "streamGenerateContent")
      end

      # Build a models list request parameters
      # @param page_size [Integer, nil] Number of models to return per page
      # @param page_token [String, nil] Token for retrieving a specific page
      # @return [Hash] The query parameters for models listing
      def build_models_list_params(page_size = nil, page_token = nil)
        params = {}
        params[:pageSize] = page_size if page_size
        params[:pageToken] = page_token if page_token
        params
      end

      # Build a specific model endpoint for the get model info API
      # @param model_name [String] The model name or ID to get info for
      # @return [String] The complete API endpoint path for getting model info
      def build_get_model_endpoint(model_name)
        # Handle both formats: "models/gemini-2.0-flash" or just "gemini-2.0-flash"
        unless model_name.start_with?("models/")
          model_name = "models/#{model_name}"
        end
        model_name
      end

      # Build the endpoint for embedding generation
      # @param model_name [String] The name of the model
      # @return [String] The complete API endpoint path for embedding generation
      def build_embedding_endpoint(model_name)
        build_model_endpoint(model_name, "embedContent")
      end
    end
  end
end
