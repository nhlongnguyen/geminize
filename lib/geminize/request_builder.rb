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
    end
  end
end
