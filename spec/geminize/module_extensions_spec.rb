# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize do
  describe "function calling and JSON mode extensions" do
    before do
      # Mock the TextGeneration class
      @mock_generator = instance_double(Geminize::TextGeneration)
      allow(Geminize::TextGeneration).to receive(:new).and_return(@mock_generator)

      # Configure with a dummy API key
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.default_model = "test-model"
        config.api_version = "v1" # Add explicit API version
      end
    end

    after do
      Geminize.reset_configuration!
    end

    describe ".generate_with_functions" do
      let(:prompt) { "What's the weather in New York?" }
      let(:functions) do
        [
          {
            name: "get_weather",
            description: "Get the current weather for a location",
            parameters: {
              type: "object",
              properties: {
                location: {
                  type: "string",
                  description: "The city and state, e.g. New York, NY"
                }
              },
              required: ["location"]
            }
          }
        ]
      end
      let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }

      it "creates a ContentRequest with functions and generates content" do
        # Expect generate_with_retries to be called with a ContentRequest that has functions
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.tools).to be_an(Array)
          expect(request.tools.size).to eq(1)
          expect(request.tools.first.function_declaration.name).to eq("get_weather")
          expect(max_retries).to eq(3)
          expect(retry_delay).to eq(1.0)
          mock_response
        end

        result = Geminize.generate_with_functions(prompt, functions)
        expect(result).to be(mock_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_response
        end

        result = Geminize.generate_with_functions(prompt, functions, model_name)
        expect(result).to be(mock_response)
      end

      it "uses the default model when no model is provided" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq("test-model")
          mock_response
        end

        result = Geminize.generate_with_functions(prompt, functions)
        expect(result).to be(mock_response)
      end

      it "passes generation parameters" do
        params = { temperature: 0.5, max_tokens: 100 }

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:generationConfig][:temperature]).to eq(0.5)
          expect(request.to_hash[:generationConfig][:maxOutputTokens]).to eq(100)
          mock_response
        end

        result = Geminize.generate_with_functions(prompt, functions, nil, params)
        expect(result).to be(mock_response)
      end

      it "sets tool execution mode when provided" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.tool_config.execution_mode).to eq("MANUAL")
          mock_response
        end

        result = Geminize.generate_with_functions(prompt, functions, nil, { tool_execution_mode: "MANUAL" })
        expect(result).to be(mock_response)
      end

      it "uses retries by default" do
        expect(@mock_generator).to receive(:generate_with_retries).and_return(mock_response)

        result = Geminize.generate_with_functions(prompt, functions)
        expect(result).to be(mock_response)
      end

      it "skips retries when requested" do
        expect(@mock_generator).to receive(:generate).and_return(mock_response)
        expect(@mock_generator).not_to receive(:generate_with_retries)

        result = Geminize.generate_with_functions(prompt, functions, nil, { with_retries: false })
        expect(result).to be(mock_response)
      end
    end

    describe ".generate_json" do
      let(:prompt) { "List three planets with their diameters" }
      let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }

      it "creates a ContentRequest with JSON mode enabled" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.response_mime_type).to eq("application/json")
          expect(request.to_hash[:generationConfig][:responseMimeType]).to eq("application/json")
          mock_response
        end

        result = Geminize.generate_json(prompt)
        expect(result).to be(mock_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_response
        end

        result = Geminize.generate_json(prompt, model_name)
        expect(result).to be(mock_response)
      end

      it "uses the default model when no model is provided" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq("test-model")
          mock_response
        end

        result = Geminize.generate_json(prompt)
        expect(result).to be(mock_response)
      end

      it "passes generation parameters" do
        params = { temperature: 0.3, system_instruction: "Return accurate data" }

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:generationConfig][:temperature]).to eq(0.3)
          system_instruction = request.to_hash[:systemInstruction]
          expect(system_instruction).to be_a(Hash)
          expect(system_instruction[:parts]).to be_an(Array)
          expect(system_instruction[:parts].first[:text]).to include("Return accurate data")
          mock_response
        end

        result = Geminize.generate_json(prompt, nil, params)
        expect(result).to be(mock_response)
      end

      it "uses retries by default" do
        expect(@mock_generator).to receive(:generate_with_retries).and_return(mock_response)

        result = Geminize.generate_json(prompt)
        expect(result).to be(mock_response)
      end

      it "skips retries when requested" do
        expect(@mock_generator).to receive(:generate).and_return(mock_response)
        expect(@mock_generator).not_to receive(:generate_with_retries)

        result = Geminize.generate_json(prompt, nil, { with_retries: false })
        expect(result).to be(mock_response)
      end
    end

    describe ".process_function_call" do
      let(:function_response) do
        instance_double(Geminize::Models::FunctionResponse,
          name: "get_weather",
          response: { "location" => "New York, NY" }
        )
      end

      let(:content_response) do
        instance_double(Geminize::Models::ContentResponse,
          has_function_call?: true,
          function_call: function_response
        )
      end

      let(:mock_final_response) { instance_double(Geminize::Models::ContentResponse) }

      it "requires a block" do
        expect {
          Geminize.process_function_call(content_response)
        }.to raise_error(Geminize::ValidationError, /block must be provided/i)
      end

      it "raises an error if response has no function call" do
        no_function_response = instance_double(Geminize::Models::ContentResponse,
          has_function_call?: false
        )

        expect {
          Geminize.process_function_call(no_function_response) { |_, _| }
        }.to raise_error(Geminize::ValidationError, /does not contain a function call/i)
      end

      it "executes the provided block with function name and args" do
        block_executed = false
        block_name = nil
        block_args = nil

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("get_weather")
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("temperature")
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("Sunny")
          mock_final_response
        end

        Geminize.process_function_call(content_response) do |name, args|
          block_executed = true
          block_name = name
          block_args = args
          { "temperature" => 22, "conditions" => "Sunny" }
        end

        expect(block_executed).to be true
        expect(block_name).to eq("get_weather")
        expect(block_args).to eq({ "location" => "New York, NY" })
      end

      it "creates a ContentRequest with the function result" do
        # The function result we'll return from the block
        function_result = { "temperature" => 22, "conditions" => "Sunny" }

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          # Expect the request to include info about the function result
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("Function")
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("get_weather")
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("temperature")
          expect(request.to_hash[:contents].first[:parts].first[:text]).to include("Sunny")
          mock_final_response
        end

        result = Geminize.process_function_call(content_response) do |_, _|
          function_result
        end

        expect(result).to be(mock_final_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"
        function_result = { "result" => "data" }

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_final_response
        end

        result = Geminize.process_function_call(content_response, model_name) do |_, _|
          function_result
        end

        expect(result).to be(mock_final_response)
      end
    end
  end
end
