# frozen_string_literal: true

require "json"

module Geminize
  # Utility class for parsing error responses from the Gemini API
  class ErrorParser
    # Parse an error response and extract relevant information
    # @param response [Faraday::Response] The response object
    # @return [Hash] Hash containing extracted error information
    def self.parse(response)
      new(response).parse
    end

    # @return [Faraday::Response] The response object
    attr_reader :response

    # Initialize a new parser
    # @param response [Faraday::Response] The response object
    def initialize(response)
      @response = response
    end

    # Parse the response and extract error information
    # @return [Hash] Hash containing error code, message, and status
    def parse
      {
        http_status: response.status,
        code: extract_error_code,
        message: extract_error_message
      }
    end

    private

    # Extract the error code from the response
    # @return [String, nil] The error code or nil if not present
    def extract_error_code
      return nil unless parsed_body && parsed_body["error"]

      if parsed_body["error"].is_a?(Hash)
        code = parsed_body["error"]["code"] || parsed_body["error"]["status"]
        code&.to_s # Use safe navigation operator
      elsif parsed_body["error"].is_a?(String)
        # Extract error code from string if possible
        parsed_body["error"].scan(/code[:\s]+([A-Z_]+)/i).flatten.first
      end
    end

    # Extract the error message from the response
    # @return [String] The error message
    def extract_error_message
      return default_error_message unless parsed_body

      if parsed_body["error"].is_a?(Hash)
        if parsed_body["error"]["message"]
          parsed_body["error"]["message"]
        else
          detailed_message = extract_detailed_error_message
          detailed_message || default_error_message
        end
      elsif parsed_body["error"].is_a?(String)
        parsed_body["error"]
      else
        default_error_message
      end
    end

    # Extract a detailed error message from nested error structures
    # @return [String, nil] Detailed error message if present
    def extract_detailed_error_message
      return nil unless parsed_body["error"].is_a?(Hash)

      details = parsed_body["error"]["details"]
      return nil unless details.is_a?(Array) && !details.empty?

      # Try to extract messages from details
      messages = details.map do |detail|
        if detail.is_a?(Hash) && detail["@type"] && detail["@type"].include?("type.googleapis.com")
          detail["detail"] || detail["description"] || detail["message"]
        end
      end.compact

      messages.join(". ") unless messages.empty?
    end

    # Parses the JSON response body
    # @return [Hash, nil] The parsed JSON or nil if parsing fails
    def parsed_body
      @parsed_body ||= begin
        return nil if response.body.to_s.empty?

        JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end
    end

    # Generate a default error message based on HTTP status
    # @return [String] A default error message
    def default_error_message
      case response.status
      when 400
        "Bad Request: The server could not process the request"
      when 401
        "Unauthorized: Authentication is required or has failed"
      when 403
        "Forbidden: You don't have permission to access this resource"
      when 404
        "Not Found: The requested resource could not be found"
      when 429
        "Too Many Requests: Rate limit exceeded"
      when 500..599
        "Server Error: The server encountered an error (#{response.status})"
      else
        "Error: An unexpected error occurred (HTTP #{response.status})"
      end
    end
  end
end
