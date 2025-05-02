# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::Tool do
  let(:function_name) { "get_weather" }
  let(:function_description) { "Get the current weather in a location" }
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
  let(:function_declaration) { Geminize::Models::FunctionDeclaration.new(function_name, function_description, function_parameters) }

  describe "#initialize with function declaration" do
    subject { described_class.new(function_declaration) }

    it "initializes with a function declaration" do
      expect(subject.function_declaration).to eq(function_declaration)
      expect(subject.code_execution).to be false
    end

    it "validates successfully" do
      expect(subject.validate!).to be true
    end

    it "returns the correct hash representation" do
      expect(subject.to_hash).to eq({
        functionDeclarations: function_declaration.to_hash
      })
    end

    it "aliases to_h to to_hash" do
      expect(subject.to_h).to eq(subject.to_hash)
    end
  end

  describe "#initialize with code execution" do
    subject { described_class.new(nil, true) }

    it "initializes with code execution enabled" do
      expect(subject.function_declaration).to be_nil
      expect(subject.code_execution).to be true
    end

    it "validates successfully" do
      expect(subject.validate!).to be true
    end

    it "returns the correct hash representation" do
      expect(subject.to_hash).to eq({
        code_execution: {}
      })
    end
  end

  describe "validation" do
    it "raises an error when neither function declaration nor code execution is provided" do
      expect { described_class.new(nil, false) }
        .to raise_error(Geminize::ValidationError, /Either function_declaration or code_execution must be provided/)
    end

    it "raises an error when function_declaration is not a FunctionDeclaration" do
      expect { described_class.new("not a function declaration") }
        .to raise_error(Geminize::ValidationError, /Function declaration must be a FunctionDeclaration/)
    end
  end
end
