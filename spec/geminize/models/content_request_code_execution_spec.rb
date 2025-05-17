# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentRequest do
  let(:prompt) { "Calculate the first 10 prime numbers" }
  let(:model_name) { "gemini-2.0-flash" }
  let(:content_request) { described_class.new(prompt, model_name) }

  describe "#enable_code_execution" do
    it "adds a code execution tool to the request" do
      expect(content_request.tools).to be_nil

      content_request.enable_code_execution

      expect(content_request.tools).to be_an(Array)
      expect(content_request.tools.size).to eq(1)
      expect(content_request.tools[0].code_execution).to be true
    end

    it "allows method chaining" do
      expect(content_request.enable_code_execution).to eq(content_request)
    end
  end

  describe "to_hash with code execution" do
    before do
      content_request.enable_code_execution
    end

    it "includes code execution tool in the hash" do
      hash = content_request.to_hash
      expect(hash[:tools]).to be_an(Array)
      expect(hash[:tools][0]).to eq({code_execution: {}})
    end

    it "includes content, model, and code execution tool" do
      hash = content_request.to_hash

      # Check that content is included
      expect(hash[:contents][0][:parts][0][:text]).to eq(prompt)

      # Check that code execution tool is included
      expect(hash[:tools][0]).to eq({code_execution: {}})
    end
  end

  describe "request with both function and code execution" do
    it "supports both function and code execution tools" do
      # Add a function
      content_request.add_function(
        "get_data",
        "Get data about something",
        {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "The query to search for"
            }
          },
          required: ["query"]
        }
      )

      # Enable code execution
      content_request.enable_code_execution

      # Validate the request has both tools
      expect(content_request.tools.size).to eq(2)
      expect(content_request.tools[0].function_declaration).not_to be_nil
      expect(content_request.tools[1].code_execution).to be true

      # Check hash representation
      hash = content_request.to_hash
      expect(hash[:tools].size).to eq(2)
    end
  end
end
