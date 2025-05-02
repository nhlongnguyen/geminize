# frozen_string_literal: true

module Geminize
  class << self
    # Generate text with function calling capabilities
    # @param prompt [String] The input prompt
    # @param functions [Array<Hash>] Array of function definitions
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [String] :tool_execution_mode Tool execution mode ("AUTO", "MANUAL", or "NONE")
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @return [Geminize::Models::ContentResponse] The generated response
    # @raise [Geminize::Error] If the generation fails
    # @example Generate text with a function call
    #   Geminize.generate_with_functions(
    #     "What's the weather in New York?",
    #     [
    #       {
    #         name: "get_weather",
    #         description: "Get the current weather in a location",
    #         parameters: {
    #           type: "object",
    #           properties: {
    #             location: {
    #               type: "string",
    #               description: "The city and state, e.g. New York, NY"
    #             },
    #             unit: {
    #               type: "string",
    #               enum: ["celsius", "fahrenheit"],
    #               description: "The unit of temperature"
    #             }
    #           },
    #           required: ["location"]
    #         }
    #       }
    #     ]
    #   )
    def generate_with_functions(prompt, functions, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Parse functions
      if functions.nil? || !functions.is_a?(Array) || functions.empty?
        raise Geminize::ValidationError.new(
          "Functions must be a non-empty array",
          "INVALID_ARGUMENT"
        )
      end

      # Set up params with defaults
      generation_params = params.dup
      tool_execution_mode = generation_params.delete(:tool_execution_mode) || "AUTO"
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction to ensure function calling
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You are a helpful assistant. When you encounter a question that you can answer by calling a function, you must always use the provided function. Always respond using the function call format, not with your own text. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Add functions to the request
      functions.each do |function|
        content_request.add_function(
          function[:name],
          function[:description],
          function[:parameters]
        )
      end

      # Set the tool config
      content_request.set_tool_config(tool_execution_mode)

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate JSON output from a prompt using the Gemini API
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @option params [Hash] :json_schema Schema for the JSON output (optional)
    # @return [Geminize::Models::ContentResponse] The generated response with JSON content
    # @raise [Geminize::Error] If the generation fails
    # @example Generate JSON output
    #   response = Geminize.generate_json(
    #     "List 3 planets with their diameter",
    #     nil,
    #     system_instruction: "Return the information as a JSON array"
    #   )
    #   planets = response.json_response # Returns parsed JSON
    def generate_json(prompt, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Set up params with defaults
      generation_params = params.dup
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction for JSON output
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You must respond with valid JSON only, with no explanation or other text. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Enable JSON mode
      content_request.enable_json_mode

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Process a function call by executing a provided block and returning the result to Gemini
    # @param response [Geminize::Models::ContentResponse] The response containing a function call
    # @param model_name [String, nil] The model to use for the followup, defaults to the configured default model
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @yield [function_name, args] Block to execute the function
    # @yieldparam function_name [String] The name of the function to execute
    # @yieldparam args [Hash] The arguments to pass to the function
    # @yieldreturn [Hash, Array, String, Numeric, Boolean, nil] The result of the function
    # @return [Geminize::Models::ContentResponse] The response after processing the function
    # @raise [Geminize::Error] If processing fails
    # @example Process a function call
    #   response = Geminize.generate_with_functions("What's the weather in New York?", [...])
    #   if response.has_function_call?
    #     final_response = Geminize.process_function_call(response) do |function_name, args|
    #       if function_name == "get_weather"
    #         # Call a real weather API here
    #         { temperature: 72, conditions: "sunny" }
    #       end
    #     end
    #     puts final_response.text
    #   end
    def process_function_call(response, model_name = nil, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Ensure a block is provided
      unless block_given?
        raise Geminize::ValidationError.new(
          "A block must be provided to process the function call",
          "INVALID_ARGUMENT"
        )
      end

      # Ensure the response has a function call
      unless response.has_function_call?
        raise Geminize::ValidationError.new(
          "The response does not contain a function call",
          "INVALID_ARGUMENT"
        )
      end

      # Extract function call information
      function_call = response.function_call
      function_name = function_call.name
      function_args = function_call.response

      # Call the provided block with the function information
      result = yield(function_name, function_args)

      # Create a function response
      Models::FunctionResponse.new(function_name, result)

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Create a request with the function result
      content_request = Models::ContentRequest.new(
        "Function #{function_name} returned: #{result.inspect}",
        model_name || configuration.default_model
      )

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with code execution capabilities
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @return [Geminize::Models::ContentResponse] The generated response
    # @raise [Geminize::Error] If the generation fails
    # @example Generate text with code execution
    #   Geminize.generate_with_code_execution(
    #     "What is the sum of the first 50 prime numbers?",
    #     nil,
    #     { temperature: 0.2 }
    #   )
    def generate_with_code_execution(prompt, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Set up params with defaults
      generation_params = params.dup
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction to ensure code execution is effective
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You are a helpful assistant with the ability to generate and execute Python code. When appropriate, use code to solve problems or complete tasks. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Enable code execution
      content_request.enable_code_execution

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end
  end
end
