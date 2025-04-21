# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::RequestBuilder do
  describe ".build_text_generation_request" do
    let(:prompt) { "Tell me a story about a dragon" }
    let(:model_name) { "gemini-1.5-pro-latest" }
    let(:content_request) do
      Geminize::Models::ContentRequest.new(
        prompt,
        model_name,
        temperature: 0.7,
        max_tokens: 100
      )
    end

    it "builds a complete request hash with model name" do
      request = described_class.build_text_generation_request(content_request)

      expect(request[:model]).to eq(model_name)
      expect(request[:contents]).to eq(content_request.to_hash[:contents])
      expect(request[:generationConfig]).to eq(content_request.to_hash[:generationConfig])
    end

    it "validates the model name" do
      allow(content_request).to receive(:model_name).and_return(nil)

      expect { described_class.build_text_generation_request(content_request) }.to raise_error(
        Geminize::ValidationError, "Model name cannot be nil"
      )
    end
  end

  describe ".build_model_endpoint" do
    it "builds an endpoint path with model name and action" do
      endpoint = described_class.build_model_endpoint("gemini-1.5-pro-latest", "generateContent")
      expect(endpoint).to eq("models/gemini-1.5-pro-latest:generateContent")
    end
  end

  describe ".build_text_generation_endpoint" do
    it "builds the generateContent endpoint for a model" do
      endpoint = described_class.build_text_generation_endpoint("gemini-1.5-pro-latest")
      expect(endpoint).to eq("models/gemini-1.5-pro-latest:generateContent")
    end
  end
end
