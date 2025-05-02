# frozen_string_literal: true

module Geminize
  module Models
    # Represents an AI model from the Gemini API.
    class Model
      # @return [String] The resource name of the model
      attr_reader :name

      # @return [String] The base model ID
      attr_reader :base_model_id

      # @return [String] The model version
      attr_reader :version

      # @return [String] The display name of the model
      attr_reader :display_name

      # @return [String] The model description
      attr_reader :description

      # @return [Integer] Maximum number of input tokens allowed
      attr_reader :input_token_limit

      # @return [Integer] Maximum number of output tokens available
      attr_reader :output_token_limit

      # @return [Array<String>] Supported generation methods
      attr_reader :supported_generation_methods

      # @return [Float] Default temperature
      attr_reader :temperature

      # @return [Float] Maximum allowed temperature
      attr_reader :max_temperature

      # @return [Float] Default top_p value for nucleus sampling
      attr_reader :top_p

      # @return [Integer] Default top_k value for sampling
      attr_reader :top_k

      # @return [Hash] Raw model data from the API
      attr_reader :raw_data

      # Create a new Model instance
      # @param attributes [Hash] Model attributes
      # @option attributes [String] :name The resource name of the model
      # @option attributes [String] :base_model_id The base model ID
      # @option attributes [String] :version The model version
      # @option attributes [String] :display_name The display name of the model
      # @option attributes [String] :description The model description
      # @option attributes [Integer] :input_token_limit Maximum input tokens
      # @option attributes [Integer] :output_token_limit Maximum output tokens
      # @option attributes [Array<String>] :supported_generation_methods Supported methods
      # @option attributes [Float] :temperature Default temperature
      # @option attributes [Float] :max_temperature Maximum temperature
      # @option attributes [Float] :top_p Default top_p value
      # @option attributes [Integer] :top_k Default top_k value
      # @option attributes [Hash] :raw_data Raw model data from API
      def initialize(attributes = {})
        @name = attributes[:name]
        @base_model_id = attributes[:base_model_id]
        @version = attributes[:version]
        @display_name = attributes[:display_name]
        @description = attributes[:description]
        @input_token_limit = attributes[:input_token_limit]
        @output_token_limit = attributes[:output_token_limit]
        @supported_generation_methods = attributes[:supported_generation_methods] || []
        @temperature = attributes[:temperature]
        @max_temperature = attributes[:max_temperature]
        @top_p = attributes[:top_p]
        @top_k = attributes[:top_k]
        @raw_data = attributes[:raw_data] || {}
      end

      # Shorthand accessor for the model ID (last part of the name path)
      # @return [String] The model ID
      def id
        return nil unless @name
        @name.split("/").last
      end

      # Check if model supports a specific generation method
      # @param method [String] Generation method to check for
      # @return [Boolean] True if the model supports the method
      def supports_method?(method)
        supported_generation_methods.include?(method.to_s)
      end

      # Check if model supports content generation
      # @return [Boolean] True if the model supports content generation
      def supports_content_generation?
        supports_method?("generateContent")
      end

      # Check if model supports message generation (chat)
      # @return [Boolean] True if the model supports message generation
      def supports_message_generation?
        supports_method?("generateMessage")
      end

      # Check if model supports embedding generation
      # @return [Boolean] True if the model supports embedding generation
      def supports_embedding?
        supports_method?("embedContent")
      end

      # Check if model supports streaming content generation
      # @return [Boolean] True if the model supports streaming content generation
      def supports_streaming?
        supports_method?("streamGenerateContent")
      end

      # Convert model to a hash representation
      # @return [Hash] Hash representation of the model
      def to_h
        {
          name: name,
          id: id,
          base_model_id: base_model_id,
          version: version,
          display_name: display_name,
          description: description,
          input_token_limit: input_token_limit,
          output_token_limit: output_token_limit,
          supported_generation_methods: supported_generation_methods,
          temperature: temperature,
          max_temperature: max_temperature,
          top_p: top_p,
          top_k: top_k
        }
      end

      # Convert model to JSON string
      # @return [String] JSON representation of the model
      def to_json(*args)
        to_h.to_json(*args)
      end

      # Create a Model from API response data
      # @param data [Hash] Raw API response data
      # @return [Model] New Model instance
      def self.from_api_data(data)
        new(
          name: data["name"],
          base_model_id: data["baseModelId"],
          version: data["version"],
          display_name: data["displayName"],
          description: data["description"],
          input_token_limit: data["inputTokenLimit"],
          output_token_limit: data["outputTokenLimit"],
          supported_generation_methods: data["supportedGenerationMethods"] || [],
          temperature: data["temperature"],
          max_temperature: data["maxTemperature"],
          top_p: data["topP"],
          top_k: data["topK"],
          raw_data: data
        )
      end
    end
  end
end
