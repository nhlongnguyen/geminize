# frozen_string_literal: true

module Geminize
  module Models
    # Extends ContentResponse with function calling capabilities
    class ContentResponse
      # @return [Geminize::Models::FunctionResponse, nil] The function call in the response, if any
      attr_reader :function_call

      # @return [String, nil] The raw JSON response content, if this is a JSON response
      attr_reader :json_response

      # @return [Geminize::Models::CodeExecution::ExecutableCode, nil] The executable code in the response, if any
      attr_reader :executable_code

      # @return [Geminize::Models::CodeExecution::CodeExecutionResult, nil] The code execution result in the response, if any
      attr_reader :code_execution_result

      # Store the response data for extensions
      alias_method :original_initialize, :initialize
      def initialize(response_data)
        @response_data = response_data
        original_initialize(response_data)
        parse_function_call
        parse_json_response
        parse_code_execution
      end

      # Determine if the response contains a function call
      # @return [Boolean] true if the response contains a function call
      def has_function_call?
        !@function_call.nil?
      end

      # Determine if the response contains a JSON response
      # @return [Boolean] true if the response contains a JSON response
      def has_json_response?
        !@json_response.nil?
      end

      # Determine if the response contains executable code
      # @return [Boolean] true if the response contains executable code
      def has_executable_code?
        !@executable_code.nil?
      end

      # Determine if the response contains a code execution result
      # @return [Boolean] true if the response contains a code execution result
      def has_code_execution_result?
        !@code_execution_result.nil?
      end

      private

      # Parse the function call from the response
      def parse_function_call
        candidates = @response_data.dig("candidates") || []
        return if candidates.empty?

        content = candidates[0].dig("content") || {}
        parts = content.dig("parts") || []
        function_call_part = parts.find { |part| part.dig("functionCall") }

        if function_call_part
          function_call_data = function_call_part["functionCall"]
          function_name = function_call_data["name"]
          function_args = function_call_data["args"] || {}

          @function_call = FunctionResponse.new(function_name, function_args)
        end
      end

      # Parse JSON response if available
      def parse_json_response
        # First try to check if it's explicitly returned as JSON
        if @response_data.dig("candidates", 0, "content", "parts", 0, "text")
          text = @response_data.dig("candidates", 0, "content", "parts", 0, "text")
          begin
            @json_response = JSON.parse(text)
            return
          rescue JSON::ParserError
            # Not valid JSON, continue checking other methods
          end
        end

        # Next check if it's returned in structured format
        candidates = @response_data.dig("candidates") || []
        return if candidates.empty?

        content = candidates[0].dig("content") || {}
        parts = content.dig("parts") || []
        json_part = parts.find { |part| part.key?("structuredValue") }

        if json_part && json_part["structuredValue"]
          @json_response = json_part["structuredValue"]
        end
      end

      # Parse code execution data from the response
      def parse_code_execution
        candidates = @response_data.dig("candidates") || []
        return if candidates.empty?

        content = candidates[0].dig("content") || {}
        parts = content.dig("parts") || []

        # Find executable code
        executable_code_part = parts.find { |part| part.dig("executableCode") }
        if executable_code_part && executable_code_part["executableCode"]
          code_data = executable_code_part["executableCode"]
          language = code_data["language"] || "PYTHON"
          code = code_data["code"] || ""

          @executable_code = Geminize::Models::CodeExecution::ExecutableCode.new(language, code)
        end

        # Find code execution result
        result_part = parts.find { |part| part.dig("codeExecutionResult") }
        if result_part && result_part["codeExecutionResult"]
          result_data = result_part["codeExecutionResult"]
          outcome = result_data["outcome"] || "OUTCOME_OK"
          output = result_data["output"] || ""

          @code_execution_result = Geminize::Models::CodeExecution::CodeExecutionResult.new(outcome, output)
        end
      end
    end
  end
end
