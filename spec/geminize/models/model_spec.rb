# frozen_string_literal: true

RSpec.describe Geminize::Models::Model do
  describe ".from_api_data" do
    let(:api_data) do
      {
        "name" => "models/gemini-1.5-pro",
        "displayName" => "Gemini 1.5 Pro",
        "description" => "A powerful multimodal model for text and vision",
        "supportedGenerationMethods" => ["generateText", "generateContent"],
        "inputTokenLimit" => 30720,
        "outputTokenLimit" => 8192,
        "inputSetting" => {
          "supportMultiModal" => true
        }
      }
    end

    subject(:model) { described_class.from_api_data(api_data) }

    it "extracts the model ID correctly" do
      expect(model.id).to eq("gemini-1.5-pro")
    end

    it "sets the model name" do
      expect(model.name).to eq("Gemini 1.5 Pro")
    end

    it "extracts the version from the name" do
      expect(model.version).to eq("1.5")
    end

    it "extracts capabilities correctly" do
      expect(model.capabilities).to include("text", "vision")
    end

    it "extracts limitations correctly" do
      expect(model.limitations).to include(
        input_token_limit: 30720,
        output_token_limit: 8192
      )
    end

    it "stores the raw data" do
      expect(model.raw_data).to eq(api_data)
    end
  end

  describe "#supports?" do
    subject(:model) do
      described_class.new(
        id: "gemini-1.5-pro",
        capabilities: ["text", "vision", "embedding"]
      )
    end

    it "returns true for supported capabilities" do
      expect(model.supports?("text")).to be true
      expect(model.supports?("vision")).to be true
      expect(model.supports?("embedding")).to be true
    end

    it "returns false for unsupported capabilities" do
      expect(model.supports?("audio")).to be false
      expect(model.supports?("video")).to be false
    end

    it "is case-insensitive" do
      expect(model.supports?("TEXT")).to be true
      expect(model.supports?("Vision")).to be true
    end

    it "handles symbol inputs" do
      expect(model.supports?(:text)).to be true
      expect(model.supports?(:vision)).to be true
    end
  end

  describe "#to_h" do
    subject(:model) do
      described_class.new(
        id: "gemini-1.5-pro",
        name: "Gemini 1.5 Pro",
        version: "1.5",
        description: "A powerful model",
        capabilities: ["text", "vision"],
        limitations: {input_token_limit: 30720},
        use_cases: ["content_generation", "image_analysis"]
      )
    end

    it "returns a hash with all the model attributes" do
      hash = model.to_h

      expect(hash[:id]).to eq("gemini-1.5-pro")
      expect(hash[:name]).to eq("Gemini 1.5 Pro")
      expect(hash[:version]).to eq("1.5")
      expect(hash[:description]).to eq("A powerful model")
      expect(hash[:capabilities]).to eq(["text", "vision"])
      expect(hash[:limitations]).to eq({input_token_limit: 30720})
      expect(hash[:use_cases]).to eq(["content_generation", "image_analysis"])
    end
  end

  describe "#to_json" do
    subject(:model) do
      described_class.new(
        id: "gemini-1.5-pro",
        name: "Gemini 1.5 Pro"
      )
    end

    it "returns a JSON string representation of the model" do
      json = model.to_json
      parsed = JSON.parse(json)

      expect(parsed["id"]).to eq("gemini-1.5-pro")
      expect(parsed["name"]).to eq("Gemini 1.5 Pro")
    end
  end
end
