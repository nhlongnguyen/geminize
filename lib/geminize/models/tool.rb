# frozen_string_literal: true

module Geminize
  module Models
    # Represents a tool for function calling or code execution in Gemini API
    class Tool
      # @return [Geminize::Models::FunctionDeclaration, nil] The function declaration for this tool
      attr_reader :function_declaration

      # @return [Boolean] Whether this tool is a code execution tool
      attr_reader :code_execution

      # Initialize a new tool
      # @param function_declaration [Geminize::Models::FunctionDeclaration, nil] The function declaration
      # @param code_execution [Boolean] Whether this is a code execution tool
      # @raise [Geminize::ValidationError] If the tool is invalid
      def initialize(function_declaration = nil, code_execution = false)
        @function_declaration = function_declaration
        @code_execution = code_execution
        validate!
      end

      # Validate the tool
      # @raise [Geminize::ValidationError] If the tool is invalid
      # @return [Boolean] true if validation passes
      def validate!
        if !@code_execution && @function_declaration.nil?
          raise Geminize::ValidationError.new(
            "Either function_declaration or code_execution must be provided",
            "INVALID_ARGUMENT"
          )
        end

        if @function_declaration && !@function_declaration.is_a?(Geminize::Models::FunctionDeclaration)
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
        if @code_execution
          {
            code_execution: {}
          }
        else
          {
            functionDeclarations: @function_declaration.to_hash
          }
        end
      end

      # Alias for to_hash
      # @return [Hash] The tool as a hash
      def to_h
        to_hash
      end
    end
  end
end
