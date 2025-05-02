# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::Tool do
  let(:function_declaration) do
    Geminize::Models::FunctionDeclaration.new(
      "get_weather",
      "Get the current weather for a location",
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
    )
  end

  describe "#initialize" do
    it "creates a valid tool" do
      tool = described_class.new(function_declaration)

      expect(tool.function_declaration).to eq(function_declaration)
    end

    it "raises an error when function_declaration is not a FunctionDeclaration" do
      expect {
        described_class.new("not a function declaration")
      }.to raise_error(Geminize::ValidationError, /must be a FunctionDeclaration/i)
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the tool" do
      function_declaration = Geminize::Models::FunctionDeclaration.new(
        "get_weather",
        "Get the current weather for a location",
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
      )
      tool = described_class.new(function_declaration)

      hash = tool.to_hash

      expect(hash[:functionDeclarations]).to eq(function_declaration.to_hash)
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      tool = described_class.new(function_declaration)

      expect(tool.to_h).to eq(tool.to_hash)
    end
  end
end
