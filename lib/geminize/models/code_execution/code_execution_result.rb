# frozen_string_literal: true

module Geminize
  module Models
    module CodeExecution
      # Represents the result of executed code
      class CodeExecutionResult
        # Valid outcome values for code execution
        VALID_OUTCOMES = ["OUTCOME_OK", "OUTCOME_ERROR"].freeze

        # @return [String] The outcome of the code execution (e.g., "OUTCOME_OK", "OUTCOME_ERROR")
        attr_reader :outcome

        # @return [String] The output from the code execution
        attr_reader :output

        # Initialize a new code execution result
        # @param outcome [String] The outcome of the code execution
        # @param output [String] The output from the code execution
        # @raise [Geminize::ValidationError] If the code execution result is invalid
        def initialize(outcome, output)
          @outcome = outcome
          @output = output
          validate!
        end

        # Validate the code execution result
        # @raise [Geminize::ValidationError] If the code execution result is invalid
        # @return [Boolean] true if validation passes
        def validate!
          unless @outcome.is_a?(String)
            raise Geminize::ValidationError.new(
              "Outcome must be a string, got #{@outcome.class}",
              "INVALID_ARGUMENT"
            )
          end

          unless VALID_OUTCOMES.include?(@outcome)
            raise Geminize::ValidationError.new(
              "Invalid outcome: #{@outcome}. Must be one of: #{VALID_OUTCOMES.join(", ")}",
              "INVALID_ARGUMENT"
            )
          end

          unless @output.is_a?(String)
            raise Geminize::ValidationError.new(
              "Output must be a string, got #{@output.class}",
              "INVALID_ARGUMENT"
            )
          end

          true
        end

        # Convert the code execution result to a hash
        # @return [Hash] The code execution result as a hash
        def to_hash
          {
            outcome: @outcome,
            output: @output
          }
        end

        # Alias for to_hash
        # @return [Hash] The code execution result as a hash
        def to_h
          to_hash
        end
      end
    end
  end
end
