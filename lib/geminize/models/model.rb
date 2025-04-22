# frozen_string_literal: true

module Geminize
  module Models
    # Represents an AI model from the Gemini API.
    class Model
      # @return [String] The unique identifier for the model
      attr_reader :id

      # @return [String] The display name of the model
      attr_reader :name

      # @return [String] The model version
      attr_reader :version

      # @return [String] The model description
      attr_reader :description

      # @return [Array<String>] List of supported capabilities (e.g., 'text', 'vision', 'embedding')
      attr_reader :capabilities

      # @return [Hash] Model limitations and constraints
      attr_reader :limitations

      # @return [Array<String>] Recommended use cases for this model
      attr_reader :use_cases

      # @return [Hash] Raw model data from the API
      attr_reader :raw_data

      # Create a new Model instance
      # @param attributes [Hash] Model attributes
      # @option attributes [String] :id The model ID
      # @option attributes [String] :name The model name
      # @option attributes [String] :version The model version
      # @option attributes [String] :description The model description
      # @option attributes [Array<String>] :capabilities List of capabilities
      # @option attributes [Hash] :limitations Model limitations
      # @option attributes [Array<String>] :use_cases Recommended use cases
      # @option attributes [Hash] :raw_data Raw model data from API
      def initialize(attributes = {})
        @id = attributes[:id]
        @name = attributes[:name]
        @version = attributes[:version]
        @description = attributes[:description]
        @capabilities = attributes[:capabilities] || []
        @limitations = attributes[:limitations] || {}
        @use_cases = attributes[:use_cases] || []
        @raw_data = attributes[:raw_data] || {}
      end

      # Check if model supports a specific capability
      # @param capability [String] Capability to check for
      # @return [Boolean] True if the model supports the capability
      def supports?(capability)
        capabilities.include?(capability.to_s.downcase)
      end

      # Convert model to a hash representation
      # @return [Hash] Hash representation of the model
      def to_h
        {
          id: id,
          name: name,
          version: version,
          description: description,
          capabilities: capabilities,
          limitations: limitations,
          use_cases: use_cases
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
        # Extract capabilities from model data
        capabilities = extract_capabilities(data)

        # Extract limitations from model data
        limitations = extract_limitations(data)

        # Extract use cases from model data
        use_cases = extract_use_cases(data)

        new(
          id: data["name"]&.split("/")&.last,
          name: data["displayName"],
          version: extract_version(data),
          description: data["description"],
          capabilities: capabilities,
          limitations: limitations,
          use_cases: use_cases,
          raw_data: data
        )
      end

      private_class_method def self.extract_version(data)
        # Extract version from model name or other fields
        # Example: if name is "gemini-1.0-pro", extract "1.0"
        if data["displayName"]
          match = data["displayName"].match(/[-_](\d+\.\d+)[-_]/)
          return match[1] if match

          # Try another pattern (e.g., "Gemini 1.5 Pro")
          match = data["displayName"].match(/\s(\d+\.\d+)\s/)
          return match[1] if match
        end
        nil
      end

      private_class_method def self.extract_capabilities(data)
        capabilities = []

        # Example capability extraction, adjust based on actual API response format
        capabilities << "text" if data.dig("supportedGenerationMethods")&.include?("generateText")
        capabilities << "chat" if data.dig("supportedGenerationMethods")&.include?("generateMessage")
        capabilities << "vision" if data.dig("supportedGenerationMethods")&.include?("generateContent") &&
                                  data.dig("inputSetting", "supportMultiModal")
        capabilities << "embedding" if data.dig("supportedGenerationMethods")&.include?("embedContent")

        capabilities
      end

      private_class_method def self.extract_limitations(data)
        limitations = {}

        # Extract token limits
        if data.dig("inputTokenLimit")
          limitations[:input_token_limit] = data["inputTokenLimit"]
        end

        if data.dig("outputTokenLimit")
          limitations[:output_token_limit] = data["outputTokenLimit"]
        end

        # Extract any other limitations from the API data
        limitations
      end

      private_class_method def self.extract_use_cases(data)
        # Extract use cases from the description or other fields
        # This is a simple implementation - adjust based on actual API data
        use_cases = []

        if data["description"]
          if data["description"].include?("chat")
            use_cases << "conversational_ai"
          end

          if data["description"].include?("vision") || data["description"].include?("image")
            use_cases << "image_understanding"
          end

          if data["description"].include?("embedding")
            use_cases << "semantic_search"
            use_cases << "clustering"
          end
        end

        use_cases
      end
    end
  end
end
