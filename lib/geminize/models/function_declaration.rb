# frozen_string_literal: true

module Geminize
  module Models
    # Represents a function declaration for function calling in Gemini API
    class FunctionDeclaration
      # @return [String] Name of the function
      attr_reader :name

      # @return [String] Description of what the function does
      attr_reader :description

      # @return [Hash] JSON schema for function parameters
      attr_reader :parameters

      # Initialize a new function declaration
      # @param name [String] The name of the function
      # @param description [String] A description of what the function does
      # @param parameters [Hash] JSON schema for function parameters
      # @raise [Geminize::ValidationError] If the function declaration is invalid
      def initialize(name, description, parameters)
        @name = name
        @description = description
        @parameters = parameters
        validate!
      end

      # Validate the function declaration
      # @raise [Geminize::ValidationError] If the function declaration is invalid
      # @return [Boolean] true if validation passes
      def validate!
        validate_name!
        validate_description!
        validate_parameters!
        true
      end

      # Convert the function declaration to a hash for API requests
      # @return [Hash] The function declaration as a hash
      def to_hash
        {
          name: @name,
          description: @description,
          parameters: @parameters
        }
      end

      # Alias for to_hash
      # @return [Hash] The function declaration as a hash
      def to_h
        to_hash
      end

      private

      # Validate the function name
      # @raise [Geminize::ValidationError] If the name is invalid
      def validate_name!
        unless @name.is_a?(String)
          raise Geminize::ValidationError.new(
            "Function name must be a string, got #{@name.class}",
            "INVALID_ARGUMENT"
          )
        end

        if @name.empty?
          raise Geminize::ValidationError.new(
            "Function name cannot be empty",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate the function description
      # @raise [Geminize::ValidationError] If the description is invalid
      def validate_description!
        unless @description.is_a?(String)
          raise Geminize::ValidationError.new(
            "Function description must be a string, got #{@description.class}",
            "INVALID_ARGUMENT"
          )
        end

        if @description.empty?
          raise Geminize::ValidationError.new(
            "Function description cannot be empty",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate the function parameters
      # @raise [Geminize::ValidationError] If the parameters are invalid
      def validate_parameters!
        unless @parameters.is_a?(Hash)
          raise Geminize::ValidationError.new(
            "Function parameters must be a hash, got #{@parameters.class}",
            "INVALID_ARGUMENT"
          )
        end

        # Validate that the parameters follow JSON Schema format
        unless @parameters.key?(:type) || @parameters.key?("type")
          raise Geminize::ValidationError.new(
            "Function parameters must include a 'type' field",
            "INVALID_ARGUMENT"
          )
        end
      end
    end
  end
end
