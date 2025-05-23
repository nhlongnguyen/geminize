# frozen_string_literal: true

require "singleton"

module Geminize
  # Handles configuration options for the Geminize gem
  class Configuration
    include Singleton

    # Base URL for the Google Gemini API
    API_BASE_URL = "https://generativelanguage.googleapis.com"

    # Default API version
    DEFAULT_API_VERSION = "v1beta"

    # Default model
    DEFAULT_MODEL = "gemini-2.0-flash"

    # Default embedding model
    DEFAULT_EMBEDDING_MODEL = "gemini-embedding-exp-03-07"

    # Default timeout values (in seconds)
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_STREAMING_TIMEOUT = 300
    DEFAULT_ON_DATA_TIMEOUT = 60

    # API key for accessing the Gemini API
    # @return [String, nil]
    attr_accessor :api_key

    # API version to use
    # @return [String]
    attr_accessor :api_version

    # Default model to use if not specified in requests
    # @return [String]
    attr_accessor :default_model

    # Default embedding model to use if not specified in embedding requests
    # @return [String]
    attr_accessor :default_embedding_model

    # Request timeout in seconds
    # @return [Integer]
    attr_accessor :timeout

    # Connection open timeout in seconds
    # @return [Integer]
    attr_accessor :open_timeout

    # Streaming request timeout in seconds
    # @return [Integer]
    attr_accessor :streaming_timeout

    # Timeout between data chunks in streaming responses
    # @return [Integer]
    attr_accessor :on_data_timeout

    # @return [Boolean]
    attr_accessor :log_requests

    # Initialize with default configuration values
    def initialize
      reset!
    end

    # Reset configuration to default values
    # @return [void]
    def reset!
      @api_key = ENV["GEMINI_API_KEY"]
      @api_version = ENV["GEMINI_API_VERSION"] || DEFAULT_API_VERSION
      @default_model = ENV["GEMINI_MODEL"] || DEFAULT_MODEL
      @default_embedding_model = ENV["GEMINI_EMBEDDING_MODEL"] || DEFAULT_EMBEDDING_MODEL
      @timeout = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @streaming_timeout = DEFAULT_STREAMING_TIMEOUT
      @on_data_timeout = DEFAULT_ON_DATA_TIMEOUT
      @log_requests = false
    end

    # Get the base URL for the Gemini API
    # @return [String]
    def api_base_url
      API_BASE_URL
    end

    # Validates the current configuration
    # @return [Boolean]
    # @raise [ConfigurationError] if the configuration is invalid
    def validate!
      raise ConfigurationError, "API key must be set" if @api_key.nil? || @api_key.empty?
      raise ConfigurationError, "API version must be set" if @api_version.nil? || @api_version.empty?

      true
    end
  end
end
