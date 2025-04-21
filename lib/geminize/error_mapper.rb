# frozen_string_literal: true

module Geminize
  # Maps API error responses to appropriate exception classes
  class ErrorMapper
    # Maps an error response to the appropriate exception
    # @param error_info [Hash] Hash containing error information (http_status, code, message)
    # @return [Geminize::GeminizeError] An instance of the appropriate exception class
    def self.map(error_info)
      new(error_info).map
    end

    # @return [Hash] The error information hash
    attr_reader :error_info

    # Initialize a new mapper
    # @param error_info [Hash] Hash containing error information (http_status, code, message)
    def initialize(error_info)
      @error_info = error_info
    end

    # Map the error to an appropriate exception
    # @return [Geminize::GeminizeError] An instance of the appropriate exception class
    def map
      error_class = determine_error_class
      error_class.new(
        error_info[:message],
        error_info[:code],
        error_info[:http_status]
      )
    end

    private

    # Determine the appropriate error class based on status code and error type
    # @return [Class] The exception class to instantiate
    def determine_error_class
      # First check for specific error codes from the API
      api_error_class = map_api_error_code
      return api_error_class if api_error_class

      # Then fall back to HTTP status code mapping
      http_status_class = map_http_status
      return http_status_class if http_status_class

      # Default to generic error
      GeminizeError
    end

    # Map error based on API-specific error codes
    # @return [Class, nil] The error class or nil if no mapping is found
    def map_api_error_code
      return nil unless error_info[:code]

      code = error_info[:code].to_s.downcase
      message = error_info[:message].to_s.downcase

      if code.include?("permission") || code.include?("unauthorized") || code.include?("unauthenticated")
        AuthenticationError
      elsif code.include?("quota") || code.include?("rate") || code.include?("limit")
        RateLimitError
      elsif code.include?("not_found") || code.include?("notfound")
        ResourceNotFoundError
      elsif code.include?("invalid") && (code.include?("model") || message.include?("model"))
        InvalidModelError
      elsif code.include?("invalid") || code.include?("validation")
        ValidationError
      elsif code.include?("blocked") || message.include?("blocked") || message.include?("safety")
        ContentBlockedError
      elsif code.include?("server") || code.include?("internal")
        ServerError
      elsif code.include?("config")
        ConfigurationError
      end
    end

    # Map error based on HTTP status code
    # @return [Class] The error class
    def map_http_status
      status = error_info[:http_status]

      case status
      when 400
        BadRequestError
      when 401, 403
        AuthenticationError
      when 404
        ResourceNotFoundError
      when 429
        RateLimitError
      when 500..599
        ServerError
      end
    end
  end
end
