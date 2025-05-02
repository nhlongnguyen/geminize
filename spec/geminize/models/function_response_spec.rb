# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::FunctionResponse do
  let(:valid_name) { "get_weather" }
  let(:valid_response) { { temperature: 22, conditions: "Sunny" } }

  describe "#initialize" do
    it "creates a valid function response" do
      function_response = described_class.new(valid_name, valid_response)

      expect(function_response.name).to eq(valid_name)
      expect(function_response.response).to eq(valid_response)
    end

    it "raises an error when name is nil" do
      expect {
        described_class.new(nil, valid_response)
      }.to raise_error(Geminize::ValidationError, /name cannot be empty/i)
    end

    it "raises an error when name is empty" do
      expect {
        described_class.new("", valid_response)
      }.to raise_error(Geminize::ValidationError, /name cannot be empty/i)
    end

    it "accepts various types for response" do
      # Hash
      expect {
        described_class.new(valid_name, { key: "value" })
      }.not_to raise_error

      # Array
      expect {
        described_class.new(valid_name, [1, 2, 3])
      }.not_to raise_error

      # String
      expect {
        described_class.new(valid_name, "text response")
      }.not_to raise_error

      # Number
      expect {
        described_class.new(valid_name, 42)
      }.not_to raise_error

      # Boolean
      expect {
        described_class.new(valid_name, true)
      }.not_to raise_error

      # Nil
      expect {
        described_class.new(valid_name, nil)
      }.not_to raise_error
    end
  end

  describe ".from_hash" do
    it "creates a function response from a hash with symbol keys" do
      hash = { name: valid_name, response: valid_response }
      function_response = described_class.from_hash(hash)

      expect(function_response.name).to eq(valid_name)
      expect(function_response.response).to eq(valid_response)
    end

    it "creates a function response from a hash with string keys" do
      hash = { "name" => valid_name, "response" => valid_response }
      function_response = described_class.from_hash(hash)

      expect(function_response.name).to eq(valid_name)
      expect(function_response.response).to eq(valid_response)
    end

    it "raises an error when input is not a hash" do
      expect {
        described_class.from_hash("not a hash")
      }.to raise_error(Geminize::ValidationError, /Expected a Hash/i)
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the function response" do
      function_response = described_class.new(valid_name, valid_response)
      hash = function_response.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:name]).to eq(valid_name)
      expect(hash[:response]).to eq(valid_response)
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      function_response = described_class.new(valid_name, valid_response)

      expect(function_response.to_h).to eq(function_response.to_hash)
    end
  end
end
