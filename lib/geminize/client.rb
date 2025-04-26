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

    # @return [Boolean] Flag indicating if a streaming operation is in progress
    attr_reader :streaming_in_progress

    # @return [Boolean] Flag indicating if a streaming operation should be cancelled
    attr_reader :cancel_streaming

    # Initialize a new client
    # @param options [Hash] Additional options to override the defaults
    # @option options [String] :api_key API key for Gemini API
    # @option options [String] :api_version API version to use
    # @option options [Integer] :timeout Request timeout in seconds
    # @option options [Integer] :open_timeout Connection open timeout in seconds
    # @option options [Integer] :streaming_timeout Timeout for streaming requests in seconds
    # @option options [Logger] :logger Custom logger instance (default: nil)
    def initialize(options = {})
      @config = Geminize.configuration
      @options = options
      @connection = build_connection
      @streaming_in_progress = false
      @cancel_streaming = false
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
    end

    # Make a streaming POST request to the specified endpoint
    # @param endpoint [String] The API endpoint path
    # @param payload [Hash] The request body
    # @param params [Hash] Optional query parameters
    # @param headers [Hash] Optional headers
    # @yield [chunk] Yields each chunk of the streaming response
    # @yieldparam chunk [String, Hash] A chunk of the response (raw text or parsed JSON)
    # @return [void]
    # @raise [Geminize::StreamingError] If the streaming request fails
    # @raise [Geminize::StreamingInterruptedError] If the connection is interrupted
    # @raise [Geminize::StreamingTimeoutError] If the streaming connection times out
    # @raise [Geminize::InvalidStreamFormatError] If the stream format is invalid
    def post_stream(endpoint, payload = {}, params = {}, headers = {}, &block)
      raise ArgumentError, "A block is required for streaming requests" unless block_given?

      # Check if another streaming operation is in progress
      if @streaming_in_progress
        raise StreamingError.new("Another streaming operation is already in progress")
      end

      @streaming_in_progress = true
      @cancel_streaming = false

      # Ensure we have alt=sse parameter for the API to get server-sent events
      params = params.merge(alt: "sse")

      # Create a separate connection for streaming
      streaming_connection = build_streaming_connection

      # Initialize buffer for SSE processing
      @buffer = ""

      # Track if we've received any data
      received_data = false

      begin
        # Make the streaming request
        streaming_connection.post(
          build_url(endpoint),
          payload.to_json,
          default_headers.merge(headers).merge({
            "Content-Type" => "application/json",
            "Accept" => "text/event-stream" # Request SSE format explicitly
          })
        ) do |req|
          req.params.merge!(add_api_key(params))

          # Configure buffer management and chunked transfer reception
          req.options.on_data = proc do |chunk, size, env|
            # Check if cancellation is requested
            if @cancel_streaming
              env[:request].http_connection.close
              raise StreamingInterruptedError.new("Streaming was cancelled by the client")
            end

            received_data = true

            # Skip empty chunks
            next if chunk.strip.empty?

            # Use a buffer for handling partial SSE messages
            @buffer += chunk

            # Process complete SSE messages in buffer
            process_buffer(&block)
          end
        end
      rescue Faraday::ConnectionFailed => e
        # Connection was established but interrupted
        if received_data
          raise StreamingInterruptedError.new("Streaming connection interrupted: #{e.message}")
        else
          raise RequestError.new("Failed to establish streaming connection: #{e.message}", "CONNECTION_ERROR", nil)
        end
      rescue Faraday::TimeoutError => e
        raise StreamingTimeoutError.new("Streaming operation timed out: #{e.message}")
      rescue JSON::ParserError => e
        raise InvalidStreamFormatError.new("Could not parse streaming response: #{e.message}")
      rescue => e
        # Generic error handler
        error_message = "Streaming error: #{e.message}"
        raise StreamingError.new(error_message, nil, nil)
      ensure
        # Always clean up resources
        @buffer = nil
        @streaming_in_progress = false
        @cancel_streaming = false

        # Reset the connection to free resources
        begin
          streaming_connection&.close if streaming_connection&.respond_to?(:close)
        rescue => e
          # Just log the error if there's a problem closing the connection
          @options[:logger]&.warn("Error closing streaming connection: #{e.message}")
        end
      end
    end

    # Set the cancel_streaming flag to cancel an in-progress streaming operation
    # @param value [Boolean] Value to set
    # @return [Boolean] The new value
    def cancel_streaming=(value)
      # Only set if a streaming operation is in progress
      return unless @streaming_in_progress

      @cancel_streaming = value
    end

    private

    # Process the buffer for complete SSE messages
    # @yield [data] Yields each parsed SSE data chunk
    # @return [void]
    def process_buffer
      # Split the buffer by double newlines, which separate SSE messages
      messages = @buffer.split(/\r\n\r\n|\n\n|\r\r/)

      # The last element might be incomplete, so keep it in the buffer
      @buffer = messages.pop || ""

      # Process each complete message
      messages.each do |message|
        # Skip empty messages
        next if message.strip.empty?

        # Extract data lines
        data_lines = []
        message.each_line do |line|
          if line.start_with?("data: ")
            data_lines << line[6..]
          end
        end

        # Skip if no data lines found
        next if data_lines.empty?

        # Join data lines for multi-line data
        data = data_lines.join("")

        # Skip "[DONE]" marker
        next if data.strip == "[DONE]"

        begin
          # Try to parse as JSON
          parsed_data = JSON.parse(data)

          # Yield parsed data regardless of type
          yield parsed_data
        rescue JSON::ParserError
          # If not valid JSON, yield as raw text
          yield data
        end
      end
    end

    # Build the Faraday connection with the configured URL and default headers
    # @return [Faraday::Connection]
    def build_connection
      Faraday.new(url: @config.api_base_url) do |conn|
        conn.options.timeout = @options[:timeout] || @config.timeout
        conn.options.open_timeout = @options[:open_timeout] || @config.open_timeout

        # Add JSON response parsing
        conn.response :json, content_type: /\bjson$/

        # Add our custom error handling middleware
        conn.response :geminize_error_handler

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

    # Build the Faraday connection optimized for streaming with the configured URL
    # @return [Faraday::Connection]
    def build_streaming_connection
      Faraday.new(url: @config.api_base_url) do |conn|
        # Set longer timeouts for streaming connections which may stay open longer
        conn.options.timeout = (@options[:streaming_timeout] || @config.streaming_timeout || 300)
        conn.options.open_timeout = (@options[:open_timeout] || @config.open_timeout)

        # Disable response parsing middleware for raw streaming
        conn.adapter :net_http do |http|
          # Configure Net::HTTP for streaming
          http.read_timeout = (@options[:streaming_timeout] || @config.streaming_timeout || 300)
          http.keep_alive_timeout = 60
          http.max_retries = 0 # Disable retries for streaming connections
        end

        # Error handling for streaming connections
        conn.response :geminize_error_handler

        # Add logging if enabled
        if @config.log_requests || @options[:logger]
          logger = @options[:logger] || Logger.new($stdout)
          conn.response :logger, logger, bodies: false
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

      if response.body.is_a?(Hash)
        response.body
      else
        JSON.parse(response.body)
      end
    rescue JSON::ParserError => e
      raise Geminize::RequestError.new("Invalid JSON response: #{e.message}", "INVALID_JSON", nil)
    end
  end
end
