# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "logger"

module Geminize
  # Client for making HTTP requests to the Gemini API
  class Client
    # @return [Faraday::Connection] The Faraday connection
    attr_reader :connection

    # Initialize a new client
    # @param options [Hash] Additional options to override the defaults
    # @option options [String] :api_key API key for Gemini API
    # @option options [String] :api_version API version to use
    # @option options [Integer] :timeout Request timeout in seconds
    # @option options [Integer] :open_timeout Connection open timeout in seconds
    # @option options [Logger] :logger Custom logger instance (default: nil)
    def initialize(options = {})
      @config = Geminize.configuration
      @options = options
      @connection = build_connection
    end

    # Make a GET request to the specified endpoint
    # @param endpoint [String] The API endpoint path
    # @param params [Hash] Optional query parameters
    # @param headers [Hash] Optional headers
    # @return [Hash] The response body parsed as JSON
    def get(endpoint, params = {}, headers = {})
      response = connection.get(
        build_url(endpoint),
        add_api_key(params),
        default_headers.merge(headers)
      )
      parse_response(response)
    rescue Faraday::Error => e
      handle_request_error(e)
    end

    # Make a POST request to the specified endpoint
    # @param endpoint [String] The API endpoint path
    # @param payload [Hash] The request body
    # @param params [Hash] Optional query parameters
    # @param headers [Hash] Optional headers
    # @return [Hash] The response body parsed as JSON
    def post(endpoint, payload = {}, params = {}, headers = {})
      response = connection.post(
        build_url(endpoint),
        payload.to_json,
        default_headers.merge(headers).merge({"Content-Type" => "application/json"})
      ) do |req|
        req.params.merge!(add_api_key(params))
      end
      parse_response(response)
    rescue Faraday::Error => e
      handle_request_error(e)
    end

    private

    # Build the Faraday connection with the configured URL and default headers
    # @return [Faraday::Connection]
    def build_connection
      Faraday.new(url: @config.api_base_url) do |conn|
        conn.options.timeout = @options[:timeout] || @config.timeout
        conn.options.open_timeout = @options[:open_timeout] || @config.open_timeout

        # Add response middleware
        conn.response :raise_error # Raise exceptions on 4xx and 5xx responses

        # Add retry middleware
        conn.request :retry, {
          max: 3,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2,
          retry_statuses: [429, 503]
        }

        # Add logging if enabled
        if @config.log_requests || @options[:logger]
          logger = @options[:logger] || Logger.new($stdout)
          conn.response :logger, logger, bodies: true
        end
      end
    end

    # Build the complete URL including API version
    # @param endpoint [String] The API endpoint path
    # @return [String] The complete URL path
    def build_url(endpoint)
      version = @options[:api_version] || @config.api_version
      "#{version}/#{endpoint}"
    end

    # Default headers for all requests
    # @return [Hash] Default headers
    def default_headers
      {
        "Accept" => "application/json"
      }
    end

    # Add API key to request parameters
    # @param params [Hash] Original parameters
    # @return [Hash] Parameters with API key added
    def add_api_key(params)
      api_key = @options[:api_key] || @config.api_key
      params.merge(key: api_key)
    end

    # Parse the response body as JSON
    # @param response [Faraday::Response] The response object
    # @return [Hash] The parsed JSON
    def parse_response(response)
      return {} if response.body.to_s.empty?

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Geminize::RequestError, "Invalid JSON response: #{e.message}"
    end

    # Handle request errors and raise appropriate exceptions
    # @param error [Faraday::Error] The Faraday error
    # @raise [Geminize::BadRequestError] For client errors (4xx)
    # @raise [Geminize::ServerError] For server errors (5xx)
    # @raise [Geminize::RequestError] For other errors
    def handle_request_error(error)
      case error
      when Faraday::ConnectionFailed, Faraday::TimeoutError
        raise Geminize::RequestError, "Network error: #{error.message}"
      when Faraday::BadRequestError, Faraday::UnauthorizedError, Faraday::ForbiddenError, Faraday::ResourceNotFound
        raise Geminize::BadRequestError, "Client error: #{error.message}"
      when Faraday::ServerError
        raise Geminize::ServerError, "Server error: #{error.message}"
      else
        raise Geminize::RequestError, "Request error: #{error.message}"
      end
    end
  end
end
