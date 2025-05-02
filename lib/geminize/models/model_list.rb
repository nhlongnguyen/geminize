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

      # @return [String, nil] Token for fetching the next page of results
      attr_reader :next_page_token

      # Delegate array methods to the underlying models array
      def_delegators :@models, :[], :size, :length, :empty?, :first, :last

      # Create a new ModelList
      # @param models [Array<Model>] Initial list of models
      # @param next_page_token [String, nil] Token for fetching the next page
      def initialize(models = [], next_page_token = nil)
        @models = models
        @next_page_token = next_page_token
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

      # Find a model by its resource name
      # @param name [String] The model name to search for
      # @return [Model, nil] The found model or nil
      def find_by_name(name)
        @models.find { |model| model.name == name }
      end

      # Find a model by its ID (last part of the resource name)
      # @param id [String] The model ID to search for
      # @return [Model, nil] The found model or nil
      def find_by_id(id)
        @models.find { |model| model.id == id }
      end

      # Find all models that support a specific generation method
      # @param method [String] The generation method to filter by
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_method(method)
        filtered = @models.select { |model| model.supports_method?(method) }
        ModelList.new(filtered, nil)
      end

      # Find all models that support content generation
      # @return [ModelList] A new ModelList containing only content generation capable models
      def content_generation_models
        filter_by_method("generateContent")
      end

      # Find all models that support streaming content generation
      # @return [ModelList] A new ModelList containing only streaming capable models
      def streaming_models
        filter_by_method("streamGenerateContent")
      end

      # Find all models that support embeddings
      # @return [ModelList] A new ModelList containing only embedding-capable models
      def embedding_models
        filter_by_method("embedContent")
      end

      # Find all models that support chat/conversation
      # @return [ModelList] A new ModelList containing only chat-capable models
      def chat_models
        filter_by_method("generateMessage")
      end

      # Filter models by version
      # @param version [String] The version to filter by
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_version(version)
        filtered = @models.select { |model| model.version == version }
        ModelList.new(filtered, nil)
      end

      # Filter models by display name pattern
      # @param pattern [String, Regexp] The pattern to match model display names against
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_display_name(pattern)
        pattern = Regexp.new(pattern.to_s, Regexp::IGNORECASE) if pattern.is_a?(String)
        filtered = @models.select { |model| model.display_name&.match?(pattern) }
        ModelList.new(filtered, nil)
      end

      # Filter models by base model ID
      # @param base_model_id [String] The base model ID to filter by
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_base_model_id(base_model_id)
        filtered = @models.select { |model| model.base_model_id == base_model_id }
        ModelList.new(filtered, nil)
      end

      # Find models with a minimum input token limit
      # @param min_limit [Integer] The minimum input token limit
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_min_input_tokens(min_limit)
        filtered = @models.select { |model| model.input_token_limit && model.input_token_limit >= min_limit }
        ModelList.new(filtered, nil)
      end

      # Find models with a minimum output token limit
      # @param min_limit [Integer] The minimum output token limit
      # @return [ModelList] A new ModelList containing only matching models
      def filter_by_min_output_tokens(min_limit)
        filtered = @models.select { |model| model.output_token_limit && model.output_token_limit >= min_limit }
        ModelList.new(filtered, nil)
      end

      # Create a ModelList from API response data
      # @param data [Hash] API response containing models
      # @return [ModelList] New ModelList instance
      def self.from_api_data(data)
        models = []
        next_page_token = data["nextPageToken"]

        # Process model data from API response
        if data.key?("models")
          models = data["models"].map do |model_data|
            Model.from_api_data(model_data)
          end
        end

        new(models, next_page_token)
      end

      # Check if there are more pages of results available
      # @return [Boolean] True if there are more pages
      def has_more_pages?
        !next_page_token.nil? && !next_page_token.empty?
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
