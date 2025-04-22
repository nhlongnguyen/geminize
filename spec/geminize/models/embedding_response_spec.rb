# frozen_string_literal: true

RSpec.describe Geminize::Models::EmbeddingResponse do
  describe "#initialize" do
    context "with a single embedding response" do
      let(:raw_response) do
        {
          "embedding" => {
            "values" => [0.1, 0.2, 0.3, 0.4, 0.5]
          }
        }
      end

      it "extracts the embedding values" do
        response = described_class.new(raw_response)
        expect(response.values).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
      end

      it "reports not being a batch" do
        response = described_class.new(raw_response)
        expect(response.batch?).to be false
      end

      it "returns the embedding as a single array" do
        response = described_class.new(raw_response)
        expect(response.embeddings).to eq([raw_response["embedding"]["values"]])
      end
    end

    context "with a batch embedding response" do
      let(:raw_response) do
        {
          "embeddings" => [
            {"values" => [0.1, 0.2, 0.3]},
            {"values" => [0.4, 0.5, 0.6]},
            {"values" => [0.7, 0.8, 0.9]}
          ]
        }
      end

      it "extracts the embedding values for each item" do
        response = described_class.new(raw_response)
        expect(response.values).to be_nil
      end

      it "reports being a batch" do
        response = described_class.new(raw_response)
        expect(response.batch?).to be true
      end

      it "returns all embeddings" do
        response = described_class.new(raw_response)
        expect(response.embeddings).to eq([
          [0.1, 0.2, 0.3],
          [0.4, 0.5, 0.6],
          [0.7, 0.8, 0.9]
        ])
      end
    end
  end

  describe "#embedding_size" do
    it "returns the size of a single embedding" do
      response = described_class.new({"embedding" => {"values" => [0.1, 0.2, 0.3, 0.4]}})
      expect(response.embedding_size).to eq(4)
    end

    it "returns the size of the first embedding in a batch" do
      response = described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3, 0.4, 0.5]},
          {"values" => [0.6, 0.7, 0.8, 0.9, 1.0]}
        ]
      })
      expect(response.embedding_size).to eq(5)
    end
  end

  describe "#batch_size" do
    it "returns 1 for a single embedding" do
      response = described_class.new({"embedding" => {"values" => [0.1, 0.2, 0.3]}})
      expect(response.batch_size).to eq(1)
    end

    it "returns the number of embeddings in a batch" do
      response = described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3]},
          {"values" => [0.4, 0.5, 0.6]},
          {"values" => [0.7, 0.8, 0.9]}
        ]
      })
      expect(response.batch_size).to eq(3)
    end
  end

  describe "validation" do
    it "raises an error when the response has no embedding data" do
      expect {
        described_class.new({})
      }.to raise_error(Geminize::ValidationError, /No embedding data found/)
    end

    it "raises an error when embedding values are not an array" do
      expect {
        described_class.new({"embedding" => {"values" => "not_an_array"}})
      }.to raise_error(Geminize::ValidationError, /Embedding values must be an array/)
    end

    it "raises an error when batch values have inconsistent sizes" do
      expect {
        described_class.new({
          "embeddings" => [
            {"values" => [0.1, 0.2, 0.3]},
            {"values" => [0.4, 0.5]} # Different size
          ]
        })
      }.to raise_error(Geminize::ValidationError, /Inconsistent embedding sizes/)
    end
  end

  # Test new convenience methods
  describe "#to_numpy_format" do
    let(:response) do
      described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3]},
          {"values" => [0.4, 0.5, 0.6]}
        ]
      })
    end

    it "returns a numpy-compatible data structure" do
      result = response.to_numpy_format
      expect(result[:data]).to eq([[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]])
      expect(result[:shape]).to eq([2, 3])
      expect(result[:dtype]).to eq("float32")
    end
  end

  describe "#top_dimensions" do
    let(:response) do
      described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3, 0.4, 0.5]},
          {"values" => [0.6, 0.7, 0.8, 0.9, 1.0]}
        ]
      })
    end

    it "extracts the top K dimensions" do
      result = response.top_dimensions(3)
      expect(result).to eq([[0.1, 0.2, 0.3], [0.6, 0.7, 0.8]])
    end

    it "raises an error when k is too large" do
      expect {
        response.top_dimensions(10)
      }.to raise_error(Geminize::ValidationError, /Cannot extract 10 dimensions/)
    end
  end

  describe "#metadata" do
    let(:response) do
      described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3]},
          {"values" => [0.4, 0.5, 0.6]}
        ],
        "usageMetadata" => {
          "promptTokenCount" => 10,
          "totalTokenCount" => 15
        }
      })
    end

    it "returns metadata about the embeddings" do
      metadata = response.metadata
      expect(metadata[:count]).to eq(2)
      expect(metadata[:dimensions]).to eq(3)
      expect(metadata[:total_tokens]).to eq(25)
      expect(metadata[:prompt_tokens]).to eq(10)
      expect(metadata[:is_batch]).to eq(true)
      expect(metadata[:is_single]).to eq(false)
    end
  end

  describe "#raw_response" do
    let(:raw_data) do
      {
        "embeddings" => [
          {"values" => [0.1, -0.2, 0.3]}
        ]
      }
    end

    it "returns the complete raw API response" do
      response = described_class.new(raw_data)
      expect(response.raw_response).to eq(raw_data)
    end
  end
end
