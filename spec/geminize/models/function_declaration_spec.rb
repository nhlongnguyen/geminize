# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::FunctionDeclaration do
  let(:valid_name) { "get_weather" }
  let(:valid_description) { "Get the current weather for a location" }
  let(:valid_parameters) do
    {
      type: "object",
      properties: {
        location: {
          type: "string",
          description: "The city and state, e.g. New York, NY"
        },
        unit: {
          type: "string",
          enum: ["celsius", "fahrenheit"],
          description: "The unit of temperature"
        }
      },
      required: ["location"]
    }
  end

  describe "#initialize" do
    it "creates a valid function declaration" do
      declaration = described_class.new(valid_name, valid_description, valid_parameters)

      expect(declaration.name).to eq(valid_name)
      expect(declaration.description).to eq(valid_description)
      expect(declaration.parameters).to eq(valid_parameters)
    end

    it "raises an error when name is nil" do
      expect {
        described_class.new(nil, valid_description, valid_parameters)
      }.to raise_error(Geminize::ValidationError, /name must be a string/i)
    end

    it "raises an error when name is empty" do
      expect {
        described_class.new("", valid_description, valid_parameters)
      }.to raise_error(Geminize::ValidationError, /name cannot be empty/i)
    end

    it "raises an error when name is not a string" do
      expect {
        described_class.new(123, valid_description, valid_parameters)
      }.to raise_error(Geminize::ValidationError, /name must be a string/i)
    end

    it "raises an error when description is nil" do
      expect {
        described_class.new(valid_name, nil, valid_parameters)
      }.to raise_error(Geminize::ValidationError, /description must be a string/i)
    end

    it "raises an error when description is empty" do
      expect {
        described_class.new(valid_name, "", valid_parameters)
      }.to raise_error(Geminize::ValidationError, /description cannot be empty/i)
    end

    it "raises an error when description is not a string" do
      expect {
        described_class.new(valid_name, 123, valid_parameters)
      }.to raise_error(Geminize::ValidationError, /description must be a string/i)
    end

    it "raises an error when parameters is not a hash" do
      expect {
        described_class.new(valid_name, valid_description, "not a hash")
      }.to raise_error(Geminize::ValidationError, /parameters must be a hash/i)
    end

    it "raises an error when parameters hash doesn't include a type field" do
      expect {
        described_class.new(valid_name, valid_description, {properties: {}})
      }.to raise_error(Geminize::ValidationError, /must include a 'type' field/i)
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the function declaration" do
      declaration = described_class.new(valid_name, valid_description, valid_parameters)
      hash = declaration.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:name]).to eq(valid_name)
      expect(hash[:description]).to eq(valid_description)
      expect(hash[:parameters]).to eq(valid_parameters)
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      declaration = described_class.new(valid_name, valid_description, valid_parameters)

      expect(declaration.to_h).to eq(declaration.to_hash)
    end
  end
end
