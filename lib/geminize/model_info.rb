# frozen_string_literal: true

require_relative "models/model"
require_relative "models/model_list"

module Geminize
  # Handles retrieving model information from the Gemini API
  class ModelInfo
    # @return [Geminize::Client] The HTTP client
    attr_reader :client

    # Initialize a new ModelInfo instance
    # @param client [Geminize::Client, nil] The HTTP client to use
    # @param options [Hash] Additional options for the client
    def initialize(client = nil, options = {})
      @client = client || Client.new(options)
      @cache = {}
      @cache_expiry = {}
      @cache_ttl = options[:cache_ttl] || 3600 # Default to 1 hour
    end

    # List available models from the Gemini API
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::ModelList] List of available models
    # @raise [Geminize::GeminizeError] If the request fails
    def list_models(force_refresh: false)
      cache_key = "models_list"

      # Check if we have a valid cached result
      if !force_refresh && @cache[cache_key] && @cache_expiry[cache_key] > Time.now
        return @cache[cache_key]
      end

      # Make the API request
      response = client.get("models")

      # Create a ModelList from the response
      model_list = Models::ModelList.from_api_data(response)

      # Cache the result
      @cache[cache_key] = model_list
      @cache_expiry[cache_key] = Time.now + @cache_ttl

      model_list
    end

    # Get information about a specific model
    # @param model_id [String] The model ID to retrieve
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::Model] The model information
    # @raise [Geminize::GeminizeError] If the request fails or model is not found
    def get_model(model_id, force_refresh: false)
      cache_key = "model_#{model_id}"

      # Check if we have a valid cached result
      if !force_refresh && @cache[cache_key] && @cache_expiry[cache_key] > Time.now
        return @cache[cache_key]
      end

      # Make the API request
      begin
        response = client.get("models/#{model_id}")

        # Create a Model from the response
        model = Models::Model.from_api_data(response)

        # Cache the result
        @cache[cache_key] = model
        @cache_expiry[cache_key] = Time.now + @cache_ttl

        model
      rescue Geminize::NotFoundError => e
        # Re-raise with a more descriptive message
        raise Geminize::NotFoundError.new("Model '#{model_id}' not found", e.code, e.http_status)
      end
    end

    # Clear all cached model information
    # @return [void]
    def clear_cache
      @cache = {}
      @cache_expiry = {}
      nil
    end

    # Set the cache time-to-live (TTL)
    # @param seconds [Integer] TTL in seconds
    # @return [void]
    def cache_ttl=(seconds)
      @cache_ttl = seconds
    end
  end
end
