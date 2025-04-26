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
        model: model_name,
        content: {
          parts: [
            {text: text}
          ]
        },
        taskType: "RETRIEVAL_DOCUMENT"
      })
    end

    it "formats a titled request properly" do
      request = described_class.new(text, model_name, title: "Sample Title")
      hash = request.to_hash

      expect(hash[:model]).to eq(model_name)
      expect(hash[:content][:parts].first).to include(text: text)
      expect(hash[:content][:title]).to eq("Sample Title")
    end

    it "formats multiple text requests with 'requests' array" do
      texts = ["First text", "Second text", "Third text"]
      request = described_class.new(texts, model_name)
      hash = request.to_hash

      expect(hash[:requests]).to be_an(Array)
      expect(hash[:requests].size).to eq(3)

      hash[:requests].each_with_index do |req, i|
        expect(req[:model]).to eq("models/#{model_name}")
        expect(req[:content][:parts]).to eq([{text: texts[i]}])
        expect(req[:taskType]).to eq("RETRIEVAL_DOCUMENT")
      end
    end

    it "includes dimensions in the request when specified" do
      request = described_class.new(text, model_name, dimensions: 768)
      hash = request.to_hash

      expect(hash[:dimensions]).to eq(768)
    end

    it "includes task type in both single and batch requests" do
      # Single request
      request = described_class.new(text, model_name, task_type: "SEMANTIC_SIMILARITY")
      hash = request.to_hash
      expect(hash[:taskType]).to eq("SEMANTIC_SIMILARITY")

      # Batch request
      texts = ["First text", "Second text"]
      batch_request = described_class.new(texts, model_name, task_type: "SEMANTIC_SIMILARITY")
      batch_hash = batch_request.to_hash

      batch_hash[:requests].each do |req|
        expect(req[:taskType]).to eq("SEMANTIC_SIMILARITY")
      end
    end
  end

  describe "#single_request_hash" do
    it "creates a properly formatted single request hash" do
      request = described_class.new(text, model_name, task_type: "CLUSTERING")
      hash = request.single_request_hash("Test text")

      expect(hash).to eq({
        model: model_name,
        content: {
          parts: [{text: "Test text"}]
        },
        taskType: "CLUSTERING"
      })
    end

    it "includes title when specified" do
      request = described_class.new(text, model_name, title: "My Title")
      hash = request.single_request_hash("Test text")

      expect(hash[:content][:title]).to eq("My Title")
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
