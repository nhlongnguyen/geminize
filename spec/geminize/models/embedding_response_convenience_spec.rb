# frozen_string_literal: true

require "tempfile"

RSpec.describe Geminize::Models::EmbeddingResponse do
  let(:single_response) do
    described_class.new({
      "embedding" => {
        "values" => [0.1, 0.2, 0.3, 0.4, 0.5]
      }
    })
  end

  let(:batch_response) do
    described_class.new({
      "embeddings" => [
        {"values" => [0.1, 0.2, 0.3, 0.4, 0.5]},
        {"values" => [0.5, 0.4, 0.3, 0.2, 0.1]},
        {"values" => [0.2, 0.3, 0.4, 0.5, 0.6]}
      ],
      "usageMetadata" => {
        "promptTokenCount" => 10,
        "totalTokenCount" => 15
      }
    })
  end

  describe "#each_embedding" do
    it "iterates through each embedding" do
      collected = []
      batch_response.each_embedding do |vec, idx|
        collected << [vec, idx]
      end

      expect(collected.length).to eq(3)
      expect(collected[0][0]).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
      expect(collected[0][1]).to eq(0)
      expect(collected[2][0]).to eq([0.2, 0.3, 0.4, 0.5, 0.6])
      expect(collected[2][1]).to eq(2)
    end

    it "returns an enumerator when no block is given" do
      enum = batch_response.each_embedding
      expect(enum).to be_a(Enumerator)
      expect(enum.to_a.length).to eq(3)
    end
  end

  describe "#to_a" do
    it "returns embeddings as an array" do
      result = batch_response.to_a
      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
      expect(result.first).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
    end
  end

  describe "#with_labels" do
    it "associates labels with embeddings" do
      labels = ["first", "second", "third"]
      result = batch_response.with_labels(labels)

      expect(result).to be_a(Hash)
      expect(result.keys).to eq(labels)
      expect(result["first"]).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
      expect(result["third"]).to eq([0.2, 0.3, 0.4, 0.5, 0.6])
    end

    it "raises an error when labels length doesn't match embeddings length" do
      expect {
        batch_response.with_labels(["one", "two"])
      }.to raise_error(Geminize::ValidationError, /Number of labels/)
    end
  end

  describe "#filter" do
    it "filters embeddings based on a condition" do
      result = batch_response.filter { |vec, _| vec[0] >= 0.2 }
      expect(result.length).to eq(2)
      expect(result).to include([0.5, 0.4, 0.3, 0.2, 0.1])
      expect(result).to include([0.2, 0.3, 0.4, 0.5, 0.6])
    end

    it "returns an enumerator when no block is given" do
      enum = batch_response.filter
      expect(enum).to be_a(Enumerator)
    end
  end

  describe "#slice" do
    it "returns a subset of embeddings" do
      result = batch_response.slice(1, 2)
      expect(result.length).to eq(2)
      expect(result[0]).to eq([0.5, 0.4, 0.3, 0.2, 0.1])
      expect(result[1]).to eq([0.2, 0.3, 0.4, 0.5, 0.6])
    end

    it "handles negative indices" do
      result = batch_response.slice(-2, -1)
      expect(result.length).to eq(2)
      expect(result[0]).to eq([0.5, 0.4, 0.3, 0.2, 0.1])
      expect(result[1]).to eq([0.2, 0.3, 0.4, 0.5, 0.6])
    end

    it "raises an error for invalid indices" do
      expect {
        batch_response.slice(5, 6)
      }.to raise_error(IndexError)

      expect {
        batch_response.slice(1, 5)
      }.to raise_error(IndexError)
    end
  end

  describe "#combine" do
    it "combines two embedding responses" do
      other_response = described_class.new({
        "embeddings" => [
          {"values" => [0.9, 0.8, 0.7, 0.6, 0.5]}
        ],
        "usageMetadata" => {
          "promptTokenCount" => 5,
          "totalTokenCount" => 5
        }
      })

      combined = batch_response.combine(other_response)
      expect(combined.batch_size).to eq(4)
      expect(combined.embeddings[3]).to eq([0.9, 0.8, 0.7, 0.6, 0.5])
      expect(combined.total_tokens).to eq(35)  # 25 from batch_response + 10 from other
    end

    it "raises an error when combining incompatible dimensions" do
      incompatible = described_class.new({
        "embeddings" => [
          {"values" => [0.1, 0.2, 0.3]}  # Different dimension
        ]
      })

      expect {
        batch_response.combine(incompatible)
      }.to raise_error(Geminize::ValidationError, /different dimensions/)
    end
  end

  describe "#save and .load" do
    it "saves and loads JSON format", :skip_in_ci do
      temp_file = Tempfile.new(["embeddings", ".json"])
      begin
        path = temp_file.path

        # Save
        batch_response.save(path, :json, pretty: true)

        # Verify file exists and has content
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0

        # Load
        loaded = described_class.load(path)
        expect(loaded.batch_size).to eq(batch_response.batch_size)
        expect(loaded.embeddings).to eq(batch_response.embeddings)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    it "saves and loads CSV format", :skip_in_ci do
      temp_file = Tempfile.new(["embeddings", ".csv"])
      begin
        path = temp_file.path

        # Save
        batch_response.save(path, :csv)

        # Verify file exists and has content
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0

        # Load
        loaded = described_class.load(path)
        expect(loaded.batch_size).to eq(batch_response.batch_size)

        # Allow for minor floating point differences from string conversion
        loaded.embeddings.each_with_index do |vec, i|
          orig_vec = batch_response.embedding_at(i)
          vec.each_with_index do |val, j|
            expect(val).to be_within(0.0001).of(orig_vec[j])
          end
        end
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end

  describe "#map_embeddings" do
    it "applies a transformation to all embeddings" do
      result = batch_response.map_embeddings { |vec, _| vec.map { |v| v * 2 } }

      expect(result.length).to eq(3)
      expect(result[0]).to eq([0.2, 0.4, 0.6, 0.8, 1.0])
      expect(result[1]).to eq([1.0, 0.8, 0.6, 0.4, 0.2])
    end

    it "provides the index to the block" do
      indices = []
      batch_response.map_embeddings { |_, idx|
        indices << idx
        []
      }
      expect(indices).to eq([0, 1, 2])
    end

    it "raises an error when the transformation returns non-array" do
      expect {
        batch_response.map_embeddings { |_, _| "not an array" }
      }.to raise_error(Geminize::ValidationError, /must return an array/)
    end
  end

  describe "#resize" do
    it "truncates embeddings to smaller dimensions" do
      result = batch_response.resize(3)
      expect(result.length).to eq(3)
      expect(result[0]).to eq([0.1, 0.2, 0.3])
      expect(result[1]).to eq([0.5, 0.4, 0.3])
    end

    it "pads embeddings to larger dimensions" do
      result = batch_response.resize(7, :pad, 0.0)
      expect(result.length).to eq(3)
      expect(result[0]).to eq([0.1, 0.2, 0.3, 0.4, 0.5, 0.0, 0.0])
      expect(result[2]).to eq([0.2, 0.3, 0.4, 0.5, 0.6, 0.0, 0.0])
    end

    it "pads with custom value" do
      result = batch_response.resize(7, :pad, -1.0)
      expect(result[0]).to eq([0.1, 0.2, 0.3, 0.4, 0.5, -1.0, -1.0])
    end
  end

  describe "#cluster" do
    it "clusters embeddings into k groups" do
      # Using deterministic data for testing
      test_data = described_class.new({
        "embeddings" => [
          {"values" => [1.0, 0.0, 0.0]},  # Cluster 1
          {"values" => [0.9, 0.1, 0.0]},  # Cluster 1
          {"values" => [0.0, 1.0, 0.0]},  # Cluster 2
          {"values" => [0.1, 0.9, 0.0]},  # Cluster 2
          {"values" => [0.0, 0.0, 1.0]},  # Cluster 3
          {"values" => [0.0, 0.1, 0.9]}   # Cluster 3
        ]
      })

      result = test_data.cluster(3, 100, :cosine)

      expect(result[:clusters].length).to eq(3)
      expect(result[:centroids].length).to eq(3)
      expect(result[:iterations]).to be > 0

      # Due to the randomness in k-means initialization, we can't make
      # deterministic assertions about which vectors end up in which clusters.
      # Instead, we'll check that the clusters are reasonable by using
      # similarities between vectors

      clusters = result[:clusters]

      clusters.each do |cluster|
        # Skip empty clusters
        next if cluster.empty?

        # Get the vectors in this cluster
        cluster_vectors = cluster.map { |idx| test_data.embedding_at(idx) }

        # Check that vectors in the same cluster are similar
        similarities = []
        cluster_vectors.combination(2).each do |v1, v2|
          similarities << Geminize::VectorUtils.cosine_similarity(v1, v2)
        end

        # If there's more than one vector in the cluster, make sure
        # they are reasonably similar (cosine similarity > 0.8)
        if similarities.any?
          expect(similarities.min).to be > 0.8
        end
      end
    end
  end
end
