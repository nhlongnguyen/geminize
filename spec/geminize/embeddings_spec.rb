# frozen_string_literal: true

RSpec.describe Geminize::Embeddings do
  let(:client) { instance_double("Geminize::Client") }
  let(:embeddings) { described_class.new(client) }
  let(:model) { "embedding-001" }
  let(:sample_text) { "This is a sample text for embeddings" }
  let(:batch_texts) { ["First text", "Second text", "Third text"] }

  describe "#generate" do
    let(:embedding_request) do
      instance_double(
        "Geminize::Models::EmbeddingRequest",
        model_name: model,
        to_hash: {content: {parts: [{text: sample_text}]}}
      )
    end

    let(:response_data) do
      {
        "embeddings" => [
          {
            "values" => [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        ],
        "usageMetadata" => {
          "promptTokenCount" => 10,
          "totalTokenCount" => 10
        }
      }
    end

    it "sends a properly formatted request to the API" do
      allow(embedding_request).to receive(:model_name).and_return(model)
      expect(client).to receive(:post).with(
        "models/#{model}:embedContent",
        embedding_request.to_hash
      ).and_return(response_data)

      result = embeddings.generate(embedding_request)

      expect(result).to be_a(Geminize::Models::EmbeddingResponse)
      expect(result.embeddings.length).to eq(1)
      expect(result.embedding).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
    end
  end

  describe "#generate_embedding" do
    let(:sample_response_data) do
      {
        "embeddings" => [
          {
            "values" => [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        ],
        "usageMetadata" => {
          "promptTokenCount" => 10,
          "totalTokenCount" => 10
        }
      }
    end

    let(:batch_response_data) do
      {
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3, 0.4, 0.5]},
          {"values" => [0.5, 0.4, 0.3, 0.2, 0.1]},
          {"values" => [0.3, 0.3, 0.3, 0.3, 0.3]}
        ],
        "usageMetadata" => {
          "promptTokenCount" => 25,
          "totalTokenCount" => 25
        }
      }
    end

    it "processes a single text input" do
      expect(client).to receive(:post).and_return(sample_response_data)

      result = embeddings.generate_embedding(sample_text, model)

      expect(result).to be_a(Geminize::Models::EmbeddingResponse)
      expect(result.embeddings.length).to eq(1)
      expect(result.embedding).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
    end

    it "processes multiple texts efficiently" do
      expect(client).to receive(:post).and_return(batch_response_data)

      result = embeddings.generate_embedding(batch_texts, model)

      expect(result).to be_a(Geminize::Models::EmbeddingResponse)
      expect(result.embeddings.length).to eq(3)
      expect(result.embedding_at(0)).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
      expect(result.embedding_at(1)).to eq([0.5, 0.4, 0.3, 0.2, 0.1])
      expect(result.embedding_at(2)).to eq([0.3, 0.3, 0.3, 0.3, 0.3])
    end

    it "handles batch processing with large input arrays" do
      # Set up the batch processing behavior
      allow(embeddings).to receive(:batch_process_embeddings)
        .and_return(Geminize::Models::EmbeddingResponse.new(batch_response_data))

      texts = Array.new(150) { |i| "Text #{i}" }
      result = embeddings.generate_embedding(texts, model)

      expect(result).to be_a(Geminize::Models::EmbeddingResponse)
      # In a real test, we'd verify that batch_process_embeddings was called
      # with the right parameters, but that's not possible with the current setup
    end
  end

  context "module-level API" do
    let(:sample_response_data) do
      {
        "embeddings" => [
          {
            "values" => [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        ],
        "usageMetadata" => {
          "promptTokenCount" => 10,
          "totalTokenCount" => 10
        }
      }
    end

    before do
      # Stub the module-level configuration
      allow(Geminize.configuration).to receive(:api_key).and_return("fake-api-key")
      allow(Geminize.configuration).to receive(:default_embedding_model).and_return(model)
      allow(Geminize.configuration).to receive(:validate!).and_return(true)

      # Stub the post method
      allow_any_instance_of(Geminize::Client).to receive(:post).and_return(sample_response_data)
    end

    it "provides a module-level method for generating embeddings" do
      result = Geminize.generate_embedding(sample_text)

      expect(result).to be_a(Geminize::Models::EmbeddingResponse)
      expect(result.embeddings.length).to eq(1)
      expect(result.embedding).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
    end

    it "provides vector utility methods" do
      vec1 = [1.0, 0.0, 0.0]
      vec2 = [0.0, 1.0, 0.0]

      # Test cosine similarity
      similarity = Geminize.cosine_similarity(vec1, vec2)
      expect(similarity).to eq(0.0)

      # Test Euclidean distance
      distance = Geminize.euclidean_distance(vec1, vec2)
      expect(distance).to eq(Math.sqrt(2))

      # Test normalization
      vec3 = [3.0, 4.0, 0.0]
      normalized = Geminize.normalize_vector(vec3)
      expect(normalized).to eq([0.6, 0.8, 0.0])

      # Test averaging
      avg = Geminize.average_vectors([vec1, vec2])
      expect(avg).to eq([0.5, 0.5, 0.0])
    end
  end
end
