# frozen_string_literal: true

RSpec.describe Geminize::Models::EmbeddingRequest do
  let(:model_name) { "embedding-001" }
  let(:text) { "This is a sample text for embeddings" }

  describe "#initialize" do
    it "creates a request with proper defaults" do
      request = described_class.new(text, model_name)

      expect(request.model_name).to eq(model_name)
      expect(request.text).to eq(text)
      expect(request.title).to be_nil
      expect(request.task_type).to eq("RETRIEVAL_DOCUMENT")
    end

    it "accepts a title" do
      request = described_class.new(text, model_name, title: "Sample Title")

      expect(request.title).to eq("Sample Title")
    end

    it "accepts a task type" do
      request = described_class.new(text, model_name, task_type: "SEMANTIC_SIMILARITY")

      expect(request.task_type).to eq("SEMANTIC_SIMILARITY")
    end

    it "raises an error for invalid task types" do
      expect {
        described_class.new(text, model_name, task_type: "INVALID_TYPE")
      }.to raise_error(Geminize::ValidationError, /task_type must be one of/)
    end

    it "supports multiple texts" do
      texts = ["First text", "Second text", "Third text"]
      request = described_class.new(texts, model_name)

      expect(request.text).to eq(texts)
      expect(request.multiple?).to be true
    end
  end

  describe "#to_hash" do
    it "formats a single text request properly" do
      request = described_class.new(text, model_name)
      hash = request.to_hash

      expect(hash).to eq({
        content: {
          parts: [
            { text: text }
          ]
        },
        taskType: "RETRIEVAL_DOCUMENT"
      })
    end

    it "formats a titled request properly" do
      request = described_class.new(text, model_name, title: "Sample Title")
      hash = request.to_hash

      expect(hash[:content][:parts].first).to include(text: text)
      expect(hash[:content][:title]).to eq("Sample Title")
    end

    it "formats a multiple text request properly" do
      texts = ["First text", "Second text", "Third text"]
      request = described_class.new(texts, model_name)
      hash = request.to_hash

      expect(hash[:content][:parts].size).to eq(3)
      expect(hash[:content][:parts][0]).to eq({ text: texts[0] })
      expect(hash[:content][:parts][1]).to eq({ text: texts[1] })
      expect(hash[:content][:parts][2]).to eq({ text: texts[2] })
    end
  end

  describe "#multiple?" do
    it "returns false for a single text" do
      request = described_class.new(text, model_name)
      expect(request.multiple?).to be false
    end

    it "returns true for an array of texts" do
      texts = ["First text", "Second text"]
      request = described_class.new(texts, model_name)
      expect(request.multiple?).to be true
    end
  end

  describe "validation" do
    it "raises error for nil text" do
      expect {
        described_class.new(nil, model_name)
      }.to raise_error(Geminize::ValidationError, /text cannot be nil/)
    end

    it "raises error for an empty array of texts" do
      expect {
        described_class.new([], model_name)
      }.to raise_error(Geminize::ValidationError, /array cannot be empty/)
    end

    it "raises error for nil model name" do
      # Mock the configuration for this test
      allow(Geminize.configuration).to receive(:default_embedding_model).and_return(nil)

      expect {
        described_class.new(text, nil)
      }.to raise_error(Geminize::ValidationError, /model_name cannot be nil/)
    end
  end
end
