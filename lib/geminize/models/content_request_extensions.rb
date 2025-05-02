# frozen_string_literal: true

module Geminize
  module Models
    # Extends ContentRequest with function calling and JSON mode support
    class ContentRequest
      # Additional attributes for function calling and JSON mode

      # @return [Array<Geminize::Models::Tool>] The tools for this request
      attr_reader :tools

      # @return [Geminize::Models::ToolConfig, nil] The tool configuration
      attr_reader :tool_config

      # @return [String, nil] The MIME type for the response format
      attr_accessor :response_mime_type

      # Add a function to the request
      # @param name [String] The name of the function
      # @param description [String] A description of what the function does
      # @param parameters [Hash] JSON schema for function parameters
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the function is invalid
      def add_function(name, description, parameters)
        @tools ||= []

        function_declaration = FunctionDeclaration.new(name, description, parameters)
        tool = Tool.new(function_declaration)

        @tools << tool
        self
      end

      # Set the tool config for function execution
      # @param execution_mode [String] The execution mode for functions ("AUTO", "MANUAL", or "NONE")
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the tool config is invalid
      def set_tool_config(execution_mode = "AUTO")
        @tool_config = ToolConfig.new(execution_mode)
        self
      end

      # Enable JSON mode for structured output
      # @return [self] The request object for chaining
      def enable_json_mode
        @response_mime_type = "application/json"
        self
      end

      # Disable JSON mode and return to regular text output
      # @return [self] The request object for chaining
      def disable_json_mode
        @response_mime_type = nil
        self
      end

      # Override the to_hash method to include additional function calling features
      # @return [Hash] The request as a hash
      def to_hash
        # First get the base implementation's hash by calling the standard method
        # Use the implementation from ContentRequest directly
        request = {
          contents: [
            {
              parts: @content_parts.map do |part|
                if part[:type] == "text"
                  {text: part[:text]}
                elsif part[:type] == "image"
                  {
                    inlineData: {
                      mimeType: part[:mime_type],
                      data: part[:data]
                    }
                  }
                end
              end.compact
            }
          ]
        }

        # Add generation config
        if @temperature || @max_tokens || @top_p || @top_k || @stop_sequences
          request[:generationConfig] = {}
          request[:generationConfig][:temperature] = @temperature if @temperature
          request[:generationConfig][:maxOutputTokens] = @max_tokens if @max_tokens
          request[:generationConfig][:topP] = @top_p if @top_p
          request[:generationConfig][:topK] = @top_k if @top_k
          request[:generationConfig][:stopSequences] = @stop_sequences if @stop_sequences
        end

        # Add system instruction
        if @system_instruction
          request[:systemInstruction] = {
            parts: [
              {
                text: @system_instruction
              }
            ]
          }
        end

        # Add tools if present
        if @tools && !@tools.empty?
          request[:tools] = @tools.map(&:to_hash)
        end

        # Add tool config if present
        if @tool_config
          request[:toolConfig] = @tool_config.to_hash
        end

        # Add response format if JSON mode is enabled
        if @response_mime_type
          request[:generationConfig] ||= {}
          request[:generationConfig][:responseSchema] = {
            type: "object",
            properties: {
              # Add a sample property to satisfy the API requirement
              # This is a generic structure that will be overridden by the model's understanding
              # of what properties to include based on the prompt
              result: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    name: { type: "string" },
                    value: { type: "string" }
                  }
                }
              }
            }
          }
          request[:generationConfig][:responseMimeType] = @response_mime_type
        end

        request
      end

      # Original validate! method includes validation for tools and JSON mode
      alias_method :original_validate!, :validate!

      def validate!
        # Don't call super, instead call the original specific validations directly
        validate_prompt!
        validate_system_instruction! if @system_instruction
        validate_temperature! if @temperature
        validate_max_tokens! if @max_tokens
        validate_top_p! if @top_p
        validate_top_k! if @top_k
        validate_stop_sequences! if @stop_sequences
        validate_content_parts!

        # Then validate our extensions
        validate_tools!
        validate_tool_config!
        validate_response_mime_type!
        true
      end

      private

      # Validate the tools
      # @raise [Geminize::ValidationError] If the tools are invalid
      def validate_tools!
        return if @tools.nil? || @tools.empty?

        unless @tools.is_a?(Array)
          raise Geminize::ValidationError.new(
            "Tools must be an array, got #{@tools.class}",
            "INVALID_ARGUMENT"
          )
        end

        @tools.each_with_index do |tool, index|
          unless tool.is_a?(Tool)
            raise Geminize::ValidationError.new(
              "Tool at index #{index} must be a Tool, got #{tool.class}",
              "INVALID_ARGUMENT"
            )
          end
        end
      end

      # Validate the tool config
      # @raise [Geminize::ValidationError] If the tool config is invalid
      def validate_tool_config!
        return if @tool_config.nil?

        unless @tool_config.is_a?(ToolConfig)
          raise Geminize::ValidationError.new(
            "Tool config must be a ToolConfig, got #{@tool_config.class}",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate the response MIME type
      # @raise [Geminize::ValidationError] If the response MIME type is invalid
      def validate_response_mime_type!
        return if @response_mime_type.nil?

        unless @response_mime_type.is_a?(String)
          raise Geminize::ValidationError.new(
            "Response MIME type must be a string, got #{@response_mime_type.class}",
            "INVALID_ARGUMENT"
          )
        end

        # For now, only allow JSON
        unless @response_mime_type == "application/json"
          raise Geminize::ValidationError.new(
            "Response MIME type must be 'application/json', got #{@response_mime_type}",
            "INVALID_ARGUMENT"
          )
        end
      end
    end
  end
end
