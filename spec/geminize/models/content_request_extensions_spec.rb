# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentRequest do
  describe "function calling extensions" do
    let(:prompt) { "What's the weather in New York?" }
    let(:model_name) { "gemini-1.5-pro" }
    let(:params) { {temperature: 0.7} }
    let(:function_name) { "get_weather" }
    let(:function_description) { "Get the current weather for a location" }
    let(:function_parameters) do
      {
        type: "object",
        properties: {
          location: {
            type: "string",
            description: "The city and state, e.g. New York, NY"
          }
        },
        required: ["location"]
      }
    end

    subject { described_class.new(prompt, model_name, params) }

    describe "#add_function" do
      it "adds a valid function to the request" do
        result = subject.add_function(function_name, function_description, function_parameters)

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.tools).to be_an(Array)
        expect(subject.tools.size).to eq(1)
        expect(subject.tools.first).to be_a(Geminize::Models::Tool)
        expect(subject.tools.first.function_declaration.name).to eq(function_name)
      end

      it "allows adding multiple functions" do
        subject.add_function(function_name, function_description, function_parameters)
        subject.add_function("get_temperature", "Get temperature", {type: "object"})

        expect(subject.tools.size).to eq(2)
        expect(subject.tools[0].function_declaration.name).to eq(function_name)
        expect(subject.tools[1].function_declaration.name).to eq("get_temperature")
      end

      it "validates each function" do
        expect {
          subject.add_function("", function_description, function_parameters)
        }.to raise_error(Geminize::ValidationError, /name cannot be empty/i)
      end
    end

    describe "#set_tool_config" do
      it "sets the tool config with default value" do
        result = subject.set_tool_config

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.tool_config).to be_a(Geminize::Models::ToolConfig)
        expect(subject.tool_config.execution_mode).to eq("AUTO")
      end

      it "sets the tool config with specified value" do
        result = subject.set_tool_config("MANUAL")

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.tool_config).to be_a(Geminize::Models::ToolConfig)
        expect(subject.tool_config.execution_mode).to eq("MANUAL")
      end

      it "validates the tool config" do
        expect {
          subject.set_tool_config("INVALID")
        }.to raise_error(Geminize::ValidationError, /Invalid execution mode/i)
      end
    end

    describe "JSON mode" do
      describe "#enable_json_mode" do
        it "enables JSON mode" do
          result = subject.enable_json_mode

          expect(result).to eq(subject) # Returns self for chaining
          expect(subject.response_mime_type).to eq("application/json")
        end
      end

      describe "#disable_json_mode" do
        it "disables JSON mode" do
          subject.enable_json_mode
          result = subject.disable_json_mode

          expect(result).to eq(subject) # Returns self for chaining
          expect(subject.response_mime_type).to be_nil
        end
      end
    end

    describe "#to_hash" do
      it "includes tools in the hash representation" do
        subject.add_function(function_name, function_description, function_parameters)
        hash = subject.to_hash

        expect(hash[:tools]).to be_an(Array)
        expect(hash[:tools].first[:functionDeclarations][:name]).to eq(function_name)
        expect(hash[:tools].first[:functionDeclarations][:description]).to eq(function_description)
      end

      it "includes tool config in the hash representation" do
        subject.set_tool_config("MANUAL")
        hash = subject.to_hash

        expect(hash[:toolConfig]).to be_a(Hash)
        expect(hash[:toolConfig][:function_calling_config][:mode]).to eq("MANUAL")
      end

      it "includes JSON mode configuration when enabled" do
        subject.enable_json_mode
        hash = subject.to_hash

        expect(hash[:generationConfig][:responseMimeType]).to eq("application/json")
        expect(hash[:generationConfig][:responseSchema]).to be_a(Hash)
      end

      it "does not include tools, tool config, or JSON mode when not set" do
        hash = subject.to_hash

        expect(hash[:tools]).to be_nil
        expect(hash[:toolConfig]).to be_nil
        expect(hash[:generationConfig]).not_to include(:responseMimeType) if hash[:generationConfig]
      end
    end
  end
end
