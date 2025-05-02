# frozen_string_literal: true

module Geminize
  module Models
    # Represents a tool for function calling in Gemini API
    class Tool
      # @return [Geminize::Models::FunctionDeclaration] The function declaration for this tool
      attr_reader :function_declaration

      # Initialize a new tool
      # @param function_declaration [Geminize::Models::FunctionDeclaration] The function declaration
      # @raise [Geminize::ValidationError] If the tool is invalid
      def initialize(function_declaration)
        @function_declaration = function_declaration
        validate!
      end

      # Validate the tool
      # @raise [Geminize::ValidationError] If the tool is invalid
      # @return [Boolean] true if validation passes
      def validate!
        unless @function_declaration.is_a?(Geminize::Models::FunctionDeclaration)
          raise Geminize::ValidationError.new(
            "Function declaration must be a FunctionDeclaration, got #{@function_declaration.class}",
            "INVALID_ARGUMENT"
          )
        end

        true
      end

      # Convert the tool to a hash for API requests
      # @return [Hash] The tool as a hash
      def to_hash
        {
          functionDeclarations: @function_declaration.to_hash
        }
      end

      # Alias for to_hash
      # @return [Hash] The tool as a hash
      def to_h
        to_hash
      end
    end
  end
end
