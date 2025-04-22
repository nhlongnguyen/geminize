# frozen_string_literal: true

RSpec.describe Geminize::Models::ModelList do
  let(:model1) do
    Geminize::Models::Model.new(
      id: "gemini-1.5-pro",
      name: "Gemini 1.5 Pro",
      capabilities: ["text", "vision", "chat"]
    )
  end

  let(:model2) do
    Geminize::Models::Model.new(
      id: "gemini-1.5-flash",
      name: "Gemini 1.5 Flash",
      capabilities: ["text", "chat"]
    )
  end

  let(:model3) do
    Geminize::Models::Model.new(
      id: "embedding-001",
      name: "Embedding-001",
      capabilities: ["embedding"]
    )
  end

  let(:models) { [model1, model2, model3] }

  subject(:model_list) { described_class.new(models) }

  describe "#initialize" do
    it "initializes with an array of models" do
      expect(model_list.models).to eq(models)
    end

    it "initializes with an empty array when no models are provided" do
      empty_list = described_class.new
      expect(empty_list.models).to eq([])
    end
  end

  describe "#add" do
    let(:new_model) do
      Geminize::Models::Model.new(
        id: "gemini-2.0",
        name: "Gemini 2.0"
      )
    end

    it "adds a model to the list" do
      result = model_list.add(new_model)

      expect(result).to eq(model_list) # Returns self for chaining
      expect(model_list.models).to include(new_model)
      expect(model_list.size).to eq(4)
    end
  end

  describe "#find_by_id" do
    it "returns the model with the matching ID" do
      result = model_list.find_by_id("gemini-1.5-pro")
      expect(result).to eq(model1)
    end

    it "returns nil when no model matches the ID" do
      result = model_list.find_by_id("nonexistent-model")
      expect(result).to be_nil
    end
  end

  describe "#filter_by_capability" do
    it "returns a new ModelList with models having the specified capability" do
      result = model_list.filter_by_capability("vision")

      expect(result).to be_a(described_class)
      expect(result.size).to eq(1)
      expect(result.first).to eq(model1)
    end

    it "returns an empty ModelList when no models have the capability" do
      result = model_list.filter_by_capability("audio")

      expect(result).to be_a(described_class)
      expect(result).to be_empty
    end
  end

  describe "capability-specific filters" do
    describe "#vision_models" do
      it "returns models with vision capability" do
        result = model_list.vision_models
        expect(result.size).to eq(1)
        expect(result.first).to eq(model1)
      end
    end

    describe "#embedding_models" do
      it "returns models with embedding capability" do
        result = model_list.embedding_models
        expect(result.size).to eq(1)
        expect(result.first).to eq(model3)
      end
    end

    describe "#text_models" do
      it "returns models with text capability" do
        result = model_list.text_models
        expect(result.size).to eq(2)
        expect(result.models).to contain_exactly(model1, model2)
      end
    end

    describe "#chat_models" do
      it "returns models with chat capability" do
        result = model_list.chat_models
        expect(result.size).to eq(2)
        expect(result.models).to contain_exactly(model1, model2)
      end
    end
  end

  describe "#filter_by_name" do
    it "filters models by name using a string pattern" do
      result = model_list.filter_by_name("flash")

      expect(result.size).to eq(1)
      expect(result.first).to eq(model2)
    end

    it "filters models by name using a regexp" do
      result = model_list.filter_by_name(/Gemini/)

      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model2)
    end
  end

  describe ".from_api_data" do
    let(:api_data) do
      {
        "models" => [
          {
            "name" => "models/gemini-1.5-pro",
            "displayName" => "Gemini 1.5 Pro"
          },
          {
            "name" => "models/embedding-001",
            "displayName" => "Embedding-001"
          }
        ]
      }
    end

    it "creates a ModelList from API response data" do
      allow(Geminize::Models::Model).to receive(:from_api_data) do |data|
        Geminize::Models::Model.new(
          id: data["name"].split("/").last,
          name: data["displayName"]
        )
      end

      result = described_class.from_api_data(api_data)

      expect(result).to be_a(described_class)
      expect(result.size).to eq(2)
      expect(result.map(&:id)).to contain_exactly("gemini-1.5-pro", "embedding-001")
    end
  end

  describe "#to_a" do
    it "returns an array of model hashes" do
      result = model_list.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
      expect(result.first).to eq(model1.to_h)
    end
  end

  describe "#to_json" do
    it "returns a JSON string representation of the model list" do
      json = model_list.to_json
      parsed = JSON.parse(json)

      expect(parsed).to be_an(Array)
      expect(parsed.size).to eq(3)
      expect(parsed.first["id"]).to eq("gemini-1.5-pro")
    end
  end

  describe "enumerable methods" do
    it "implements each method" do
      collected_models = []
      model_list.each { |model| collected_models << model }

      expect(collected_models).to eq(models)
    end

    it "supports other enumerable methods" do
      result = model_list.map(&:id)
      expect(result).to eq(["gemini-1.5-pro", "gemini-1.5-flash", "embedding-001"])

      result = model_list.select { |model| model.id.start_with?("gemini") }
      expect(result.map(&:id)).to eq(["gemini-1.5-pro", "gemini-1.5-flash"])
    end
  end

  describe "delegated methods" do
    it "delegates array methods to the underlying models array" do
      expect(model_list.size).to eq(3)
      expect(model_list.length).to eq(3)
      expect(model_list.empty?).to be false
      expect(model_list.first).to eq(model1)
      expect(model_list.last).to eq(model3)
      expect(model_list[1]).to eq(model2)
    end
  end
end
