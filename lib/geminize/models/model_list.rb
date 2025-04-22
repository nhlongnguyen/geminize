# frozen_string_literal: true

require "forwardable"

module Geminize
  module Models
    # Represents a collection of AI models with filtering capabilities
    class ModelList
      include Enumerable
      extend Forwardable

      # @return [Array<Model>] The list of models
      attr_reader :models

      # Delegate array methods to the underlying models array
      def_delegators :@models, :[], :size, :length, :empty?, :first, :last

      # Create a new ModelList
      # @param models [Array<Model>] Initial list of models
      def initialize(models = [])
        @models = models
      end

      # Implement Enumerable's required each method
      # @yield [Model] Each model in the list
      def each(&block)
        @models.each(&block)
      end

      # Add a model to the list
      # @param model [Model] The model to add
      # @return [ModelList] The updated model list
      def add(model)
        @models << model
        self
      end

      # Find a model by its ID
      # @param id [String] The model ID to search for
      # @return [Model, nil] The found model or nil
      def find_by_id(id)
        @models.find { |model| model.id == id }
      end

      # Find all models that support a specific capability
      # @param capability [String] The capability to filter by
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_capability(capability)
        filtered = @models.select { |model| model.supports?(capability) }
        ModelList.new(filtered)
      end

      # Find all models that support vision capabilities
      # @return [ModelList] A new ModelList containing only vision-capable models
      def vision_models
        filter_by_capability("vision")
      end

      # Find all models that support embedding capabilities
      # @return [ModelList] A new ModelList containing only embedding-capable models
      def embedding_models
        filter_by_capability("embedding")
      end

      # Find all models that support text generation
      # @return [ModelList] A new ModelList containing only text generation models
      def text_models
        filter_by_capability("text")
      end

      # Find all models that support chat/conversation
      # @return [ModelList] A new ModelList containing only chat-capable models
      def chat_models
        filter_by_capability("chat")
      end

      # Filter models by version
      # @param version [String] The version to filter by
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_version(version)
        filtered = @models.select { |model| model.version == version }
        ModelList.new(filtered)
      end

      # Filter models by name pattern
      # @param pattern [String, Regexp] The pattern to match model names against
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_name(pattern)
        pattern = Regexp.new(pattern.to_s, Regexp::IGNORECASE) if pattern.is_a?(String)
        filtered = @models.select { |model| model.name && model.name.match?(pattern) }
        ModelList.new(filtered)
      end

      # Create a ModelList from API response data
      # @param data [Hash] API response containing models
      # @return [ModelList] New ModelList instance
      def self.from_api_data(data)
        models = []

        # Process model data from API response
        # The exact structure will depend on the Gemini API response format
        if data.key?("models")
          models = data["models"].map do |model_data|
            Model.from_api_data(model_data)
          end
        end

        new(models)
      end

      # Convert to array of hashes representation
      # @return [Array<Hash>] Array of model hashes
      def to_a
        @models.map(&:to_h)
      end

      # Convert to JSON string
      # @return [String] JSON representation
      def to_json(*args)
        to_a.to_json(*args)
      end
    end
  end
end
