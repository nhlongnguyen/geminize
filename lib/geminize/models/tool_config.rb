# frozen_string_literal: true

module Geminize
  module Models
    # Represents configuration for tool execution in Gemini API
    class ToolConfig
      # Valid execution modes for tools
      EXECUTION_MODES = ["AUTO", "MANUAL", "NONE"].freeze

      # @return [String] The execution mode for tools
      attr_reader :execution_mode

      # Initialize a new tool configuration
      # @param execution_mode [String] The execution mode for tools
      # @raise [Geminize::ValidationError] If the tool configuration is invalid
      def initialize(execution_mode = "AUTO")
        @execution_mode = execution_mode
        validate!
      end

      # Validate the tool configuration
      # @raise [Geminize::ValidationError] If the tool configuration is invalid
      # @return [Boolean] true if validation passes
      def validate!
        unless EXECUTION_MODES.include?(@execution_mode)
          raise Geminize::ValidationError.new(
            "Invalid execution mode: #{@execution_mode}. Must be one of: #{EXECUTION_MODES.join(", ")}",
            "INVALID_ARGUMENT"
          )
        end

        true
      end

      # Convert the tool configuration to a hash for API requests
      # @return [Hash] The tool configuration as a hash
      def to_hash
        {
          function_calling_config: {
            mode: @execution_mode
          }
        }
      end

      # Alias for to_hash
      # @return [Hash] The tool configuration as a hash
      def to_h
        to_hash
      end
    end
  end
end
