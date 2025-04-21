# frozen_string_literal: true

module Geminize
  # Base error class for all Geminize errors
  class GeminizeError < StandardError
    # @return [String] The error message
    attr_reader :message

    # @return [String, nil] The error code from the API response
    attr_reader :code

    # @return [Integer, nil] The HTTP status code
    attr_reader :http_status

    # Initialize a new error
    # @param message [String] The error message
    # @param code [String, nil] The error code from the API response
    # @param http_status [Integer, nil] The HTTP status code
    def initialize(message = nil, code = nil, http_status = nil)
      @message = message || "An error occurred with the Geminize API"
      @code = code
      @http_status = http_status
      super(@message)
    end
  end

  # Error raised when there's an authentication issue
  class AuthenticationError < GeminizeError
    def initialize(message = nil, code = nil, http_status = 401)
      super(
        message || "Authentication failed. Please check your API key.",
        code,
        http_status
      )
    end
  end

  # Error raised when rate limits are exceeded
  class RateLimitError < GeminizeError
    def initialize(message = nil, code = nil, http_status = 429)
      super(
        message || "Rate limit exceeded. Please retry after some time.",
        code,
        http_status
      )
    end
  end

  # Error raised for client-side errors (4xx)
  class BadRequestError < GeminizeError
    def initialize(message = nil, code = nil, http_status = 400)
      super(
        message || "Invalid request. Please check your parameters.",
        code,
        http_status
      )
    end
  end

  # Error raised for server-side errors (5xx)
  class ServerError < GeminizeError
    def initialize(message = nil, code = nil, http_status = 500)
      super(
        message || "The Gemini API encountered a server error.",
        code,
        http_status
      )
    end
  end

  # Error raised for network/request issues
  class RequestError < GeminizeError
    def initialize(message = nil, code = nil, http_status = nil)
      super(
        message || "There was an error making the request to the Gemini API.",
        code,
        http_status
      )
    end
  end

  # Error raised when a resource is not found
  class ResourceNotFoundError < BadRequestError
    def initialize(message = nil, code = nil, http_status = 404)
      super(
        message || "The requested resource was not found.",
        code,
        http_status
      )
    end
  end

  # Error raised when a requested model is invalid or not available
  class InvalidModelError < BadRequestError
    def initialize(message = nil, code = nil, http_status = 400)
      super(
        message || "The specified model is invalid or not available.",
        code,
        http_status
      )
    end
  end

  # Error raised for validation errors
  class ValidationError < BadRequestError
    def initialize(message = nil, code = nil, http_status = 400)
      super(
        message || "Validation failed. Please check your input parameters.",
        code,
        http_status
      )
    end
  end

  # Error raised when the content is blocked by the safety filters
  class ContentBlockedError < BadRequestError
    def initialize(message = nil, code = nil, http_status = 400)
      super(
        message || "Content blocked by safety filters.",
        code,
        http_status
      )
    end
  end

  # Error raised when there are configuration issues
  class ConfigurationError < GeminizeError
    def initialize(message = nil, code = nil, http_status = nil)
      super(
        message || "Configuration error. Please check your Geminize configuration.",
        code,
        http_status
      )
    end
  end
end
