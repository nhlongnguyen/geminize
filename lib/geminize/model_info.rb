# frozen_string_literal: true

require_relative "models/model"
require_relative "models/model_list"

module Geminize
  # Handles retrieving model information from the Gemini API
  class ModelInfo
    # @return [Geminize::Client] The HTTP client
    attr_reader :client

    # Default page size for listing models
    DEFAULT_PAGE_SIZE = 50

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
    # @param page_size [Integer, nil] Number of models to return per page (max 1000)
    # @param page_token [String, nil] Token for retrieving a specific page
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::ModelList] List of available models
    # @raise [Geminize::GeminizeError] If the request fails
    def list_models(page_size: nil, page_token: nil, force_refresh: false)
      cache_key = "models_list_#{page_size}_#{page_token}"

      # Check if we have a valid cached result
      if !force_refresh && @cache[cache_key] && @cache_expiry[cache_key] > Time.now
        return @cache[cache_key]
      end

      # Prepare query parameters
      params = {}
      params[:pageSize] = page_size if page_size
      params[:pageToken] = page_token

      # Make the API request
      response = client.get("models", params)

      # Create a ModelList from the response
      model_list = Models::ModelList.from_api_data(response)

      # Cache the result
      @cache[cache_key] = model_list
      @cache_expiry[cache_key] = Time.now + @cache_ttl

      model_list
    end

    # Get all available models, handling pagination automatically
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::ModelList] Complete list of all available models
    # @raise [Geminize::GeminizeError] If any request fails
    def list_all_models(force_refresh: false)
      cache_key = "all_models_list"

      # Check if we have a valid cached result
      if !force_refresh && @cache[cache_key] && @cache_expiry[cache_key] > Time.now
        return @cache[cache_key]
      end

      all_models = []
      page_token = nil

      # Fetch first page
      model_list = list_models(
        page_size: DEFAULT_PAGE_SIZE,
        page_token: page_token,
        force_refresh: force_refresh
      )
      all_models.concat(model_list.models)

      # Fetch additional pages if available
      while model_list.has_more_pages?
        page_token = model_list.next_page_token
        model_list = list_models(
          page_size: DEFAULT_PAGE_SIZE,
          page_token: page_token,
          force_refresh: force_refresh
        )
        all_models.concat(model_list.models)
      end

      # Create a consolidated model list
      result = Models::ModelList.new(all_models)

      # Cache the result
      @cache[cache_key] = result
      @cache_expiry[cache_key] = Time.now + @cache_ttl

      result
    end

    # Get information about a specific model
    # @param model_name [String] The model name to retrieve (models/{model})
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::Model] The model information
    # @raise [Geminize::GeminizeError] If the request fails or model is not found
    def get_model(model_name, force_refresh: false)
      # Handle both formats: "models/gemini-1.5-pro" or just "gemini-1.5-pro"
      unless model_name.start_with?("models/")
        model_name = "models/#{model_name}"
      end

      cache_key = "model_#{model_name}"

      # Check if we have a valid cached result
      if !force_refresh && @cache[cache_key] && @cache_expiry[cache_key] > Time.now
        return @cache[cache_key]
      end

      # Make the API request
      begin
        response = client.get(model_name)

        # Create a Model from the response
        model = Models::Model.from_api_data(response)

        # Cache the result
        @cache[cache_key] = model
        @cache_expiry[cache_key] = Time.now + @cache_ttl

        model
      rescue Geminize::NotFoundError => e
        # Re-raise with a more descriptive message
        raise Geminize::NotFoundError.new("Model '#{model_name}' not found", e.code, e.http_status)
      end
    end

    # Get models that support a specific generation method
    # @param method [String] The generation method (e.g., "generateContent", "embedContent")
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::ModelList] List of models that support the method
    # @raise [Geminize::GeminizeError] If the request fails
    def get_models_by_method(method, force_refresh: false)
      all_models = list_all_models(force_refresh: force_refresh)
      all_models.filter_by_method(method)
    end

    # Get models by base model ID
    # @param base_model_id [String] The base model ID to filter by
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @return [Geminize::Models::ModelList] List of models with the specified base model ID
    # @raise [Geminize::GeminizeError] If the request fails
    def get_models_by_base_id(base_model_id, force_refresh: false)
      all_models = list_all_models(force_refresh: force_refresh)
      all_models.filter_by_base_model_id(base_model_id)
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
    attr_writer :cache_ttl
  end
end
