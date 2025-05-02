# frozen_string_literal: true

module Geminize
  module Models
    # Represents a function response from Gemini API
    class FunctionResponse
      # @return [String] The name of the function that was called
      attr_reader :name

      # @return [Hash, Array, String, Numeric, Boolean, nil] The response from the function
      attr_reader :response

      # Initialize a new function response
      # @param name [String] The name of the function that was called
      # @param response [Hash, Array, String, Numeric, Boolean, nil] The response from the function
      def initialize(name, response)
        @name = name
        @response = response
        validate!
      end

      # Validate the function response
      # @raise [Geminize::ValidationError] If the function response is invalid
      # @return [Boolean] true if validation passes
      def validate!
        if @name.nil? || @name.empty?
          raise Geminize::ValidationError.new(
            "Function name cannot be empty",
            "INVALID_ARGUMENT"
          )
        end

        true
      end

      # Create a FunctionResponse from a hash
      # @param hash [Hash] The hash representation of a function response
      # @return [Geminize::Models::FunctionResponse] The function response
      # @raise [Geminize::ValidationError] If the hash is invalid
      def self.from_hash(hash)
        unless hash.is_a?(Hash)
          raise Geminize::ValidationError.new(
            "Expected a Hash, got #{hash.class}",
            "INVALID_ARGUMENT"
          )
        end

        name = hash["name"] || hash[:name]
        response = hash["response"] || hash[:response]

        new(name, response)
      end

      # Convert the function response to a hash
      # @return [Hash] The function response as a hash
      def to_hash
        {
          name: @name,
          response: @response
        }
      end

      # Alias for to_hash
      # @return [Hash] The function response as a hash
      def to_h
        to_hash
      end
    end
  end
end
