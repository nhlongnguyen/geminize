# frozen_string_literal: true

module Geminize
  module Models
    # Extends ContentResponse with function calling response handling
    class ContentResponse
      # Get the function call information from the response
      # @return [Geminize::Models::FunctionResponse, nil] Function call information or nil if not present
      def function_call
        return @function_call if defined?(@function_call)

        @function_call = nil
        candidates = @raw_response["candidates"]

        if candidates && !candidates.empty?
          content = candidates.first["content"]
          if content && content["parts"] && !content["parts"].empty?
            function_call_part = content["parts"].find { |part| part["functionCall"] || part["function_call"] }

            if function_call_part
              # Handle both "functionCall" and "function_call" formats (API may vary)
              function_data = function_call_part["functionCall"] || function_call_part["function_call"]

              if function_data
                # Extract name and args - handle different API response formats
                name = function_data["name"]
                args = function_data["args"] || function_data["arguments"]

                if name
                  @function_call = FunctionResponse.new(name, args || {})
                end
              end
            end
          end
        end

        @function_call
      end

      # Check if the response contains a function call
      # @return [Boolean] True if the response contains a function call
      def has_function_call?
        !function_call.nil?
      end

      # Get structured JSON response if available
      # @return [Hash, nil] Parsed JSON response or nil if not a JSON response
      def json_response
        return @json_response if defined?(@json_response)

        @json_response = nil

        if has_text?
          begin
            @json_response = JSON.parse(text)
          rescue JSON::ParserError
            # Try to parse any JSON-like content from the text
            json_match = text.match(/```json\s*(.*?)\s*```/m) || text.match(/\{.*\}/m) || text.match(/\[.*\]/m)
            if json_match
              begin
                @json_response = JSON.parse(json_match[1] || json_match[0])
              rescue JSON::ParserError
                # Still not valid JSON
                @json_response = nil
              end
            end
          end
        end

        @json_response
      end

      # Check if the response contains valid JSON
      # @return [Boolean] True if the response contains valid JSON
      def has_json_response?
        !json_response.nil?
      end

      # Enhanced parse_response method to handle function calls
      alias_method :original_parse_response, :parse_response

      private

      # Parse the response data and extract relevant information
      def parse_response
        original_parse_response
        # Clear any cached function call before parsing again
        remove_instance_variable(:@function_call) if defined?(@function_call)
        parse_function_call
      end

      # Parse function call information from the response
      def parse_function_call
        candidates = @raw_response["candidates"]

        if candidates && !candidates.empty?
          content = candidates.first["content"]
          if content && content["parts"] && !content["parts"].empty?
            function_call_part = content["parts"].find { |part| part["functionCall"] || part["function_call"] }

            if function_call_part
              # Handle both "functionCall" and "function_call" formats (API may vary)
              function_data = function_call_part["functionCall"] || function_call_part["function_call"]

              if function_data
                # Extract name and args - handle different API response formats
                name = function_data["name"]
                args = function_data["args"] || function_data["arguments"]

                if name
                  @function_call = FunctionResponse.new(name, args || {})
                end
              end
            end
          end
        end
      end
    end
  end
end
