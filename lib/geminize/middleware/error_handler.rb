# frozen_string_literal: true

require "faraday"
require "ostruct"

module Geminize
  module Middleware
    # Faraday middleware for handling API error responses
    class ErrorHandler < Faraday::Middleware
      # @return [Array<Integer>] HTTP status codes that trigger error handling
      attr_reader :error_statuses

      # Initialize the middleware
      # @param app [#call] The Faraday app
      # @param options [Hash] Configuration options
      # @option options [Array<Integer>] :error_statuses HTTP status codes to handle as errors (default: 400..599)
      def initialize(app, options = {})
        super(app)
        @error_statuses = options.fetch(:error_statuses, 400..599).to_a
      end

      # Execute the middleware
      # @param env [Faraday::Env] The request environment
      def call(env)
        @app.call(env).on_complete do |response_env|
          on_complete(response_env) if error_statuses.include?(response_env.status)
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        # Handle network errors
        raise Geminize::RequestError.new(
          "Network error: #{e.message}",
          "CONNECTION_ERROR",
          nil
        )
      end

      # Process the API response
      # @param env [Faraday::Env] The response environment
      # @raise [Geminize::GeminizeError] The appropriate exception based on the error
      def on_complete(env)
        # Create a simplified response object that we can pass to our parser
        response = build_response_for_parser(env)

        # Parse the error response
        error_info = ErrorParser.parse(response)

        # Map to appropriate exception and raise
        exception = ErrorMapper.map(error_info)
        raise exception
      end

      private

      # Build a simplified response object from the Faraday environment
      # @param env [Faraday::Env] The Faraday environment
      # @return [OpenStruct] A simplified response-like object
      def build_response_for_parser(env)
        # Create a simple struct that mimics the interface expected by ErrorParser
        OpenStruct.new(
          status: env.status,
          body: env.body,
          headers: env.response_headers
        )
      end
    end
  end
end

# Register the middleware with Faraday
Faraday::Response.register_middleware(
  geminize_error_handler: -> { Geminize::Middleware::ErrorHandler }
)
