# frozen_string_literal: true

RSpec.describe Geminize::Models::Model do
  describe ".from_api_data" do
    let(:api_data) do
      {
        "name" => "models/gemini-1.5-pro",
        "baseModelId" => "gemini-1.5-pro",
        "version" => "1.5",
        "displayName" => "Gemini 1.5 Pro",
        "description" => "A powerful multimodal model for text and vision",
        "supportedGenerationMethods" => [
          "generateContent",
          "streamGenerateContent",
          "embedContent"
        ],
        "inputTokenLimit" => 30720,
        "outputTokenLimit" => 8192,
        "temperature" => 0.7,
        "maxTemperature" => 1.0,
        "topP" => 0.9,
        "topK" => 40
      }
    end

    subject(:model) { described_class.from_api_data(api_data) }

    it "extracts the resource name correctly" do
      expect(model.name).to eq("models/gemini-1.5-pro")
    end

    it "extracts the base model ID correctly" do
      expect(model.base_model_id).to eq("gemini-1.5-pro")
    end

    it "extracts the model ID (last part of name) correctly" do
      expect(model.id).to eq("gemini-1.5-pro")
    end

    it "extracts the version correctly" do
      expect(model.version).to eq("1.5")
    end

    it "extracts the display name correctly" do
      expect(model.display_name).to eq("Gemini 1.5 Pro")
    end

    it "extracts the description correctly" do
      expect(model.description).to eq("A powerful multimodal model for text and vision")
    end

    it "extracts the token limits correctly" do
      expect(model.input_token_limit).to eq(30720)
      expect(model.output_token_limit).to eq(8192)
    end

    it "extracts the generation parameters correctly" do
      expect(model.temperature).to eq(0.7)
      expect(model.max_temperature).to eq(1.0)
      expect(model.top_p).to eq(0.9)
      expect(model.top_k).to eq(40)
    end

    it "extracts generation methods correctly" do
      expect(model.supported_generation_methods).to contain_exactly(
        "generateContent", "streamGenerateContent", "embedContent"
      )
    end

    it "stores the raw data" do
      expect(model.raw_data).to eq(api_data)
    end
  end

  describe "#supports_method?" do
    subject(:model) do
      described_class.new(
        name: "models/gemini-1.5-pro",
        supported_generation_methods: ["generateContent", "streamGenerateContent", "embedContent"]
      )
    end

    it "returns true for supported methods" do
      expect(model.supports_method?("generateContent")).to be true
      expect(model.supports_method?("streamGenerateContent")).to be true
      expect(model.supports_method?("embedContent")).to be true
    end

    it "returns false for unsupported methods" do
      expect(model.supports_method?("unknownMethod")).to be false
      expect(model.supports_method?("chatMessage")).to be false
    end
  end

  describe "capability helper methods" do
    subject(:model) do
      described_class.new(
        name: "models/gemini-1.5-pro",
        supported_generation_methods: ["generateContent", "streamGenerateContent", "embedContent"]
      )
    end

    describe "#supports_content_generation?" do
      it "returns true when generateContent is supported" do
        expect(model.supports_content_generation?).to be true
      end

      it "returns false when generateContent is not supported" do
        model = described_class.new(
          supported_generation_methods: ["embedContent"]
        )
        expect(model.supports_content_generation?).to be false
      end
    end

    describe "#supports_embedding?" do
      it "returns true when embedContent is supported" do
        expect(model.supports_embedding?).to be true
      end

      it "returns false when embedContent is not supported" do
        model = described_class.new(
          supported_generation_methods: ["generateContent"]
        )
        expect(model.supports_embedding?).to be false
      end
    end

    describe "#supports_streaming?" do
      it "returns true when streamGenerateContent is supported" do
        expect(model.supports_streaming?).to be true
      end

      it "returns false when streamGenerateContent is not supported" do
        model = described_class.new(
          supported_generation_methods: ["generateContent"]
        )
        expect(model.supports_streaming?).to be false
      end
    end

    describe "#supports_message_generation?" do
      it "returns true when generateMessage is supported" do
        model = described_class.new(
          supported_generation_methods: ["generateMessage"]
        )
        expect(model.supports_message_generation?).to be true
      end

      it "returns false when generateMessage is not supported" do
        expect(model.supports_message_generation?).to be false
      end
    end
  end

  describe "#to_h" do
    subject(:model) do
      described_class.new(
        name: "models/gemini-1.5-pro",
        base_model_id: "gemini-1.5-pro",
        version: "1.5",
        display_name: "Gemini 1.5 Pro",
        description: "A powerful model",
        input_token_limit: 30720,
        output_token_limit: 8192,
        supported_generation_methods: ["generateContent", "streamGenerateContent"],
        temperature: 0.7,
        max_temperature: 1.0,
        top_p: 0.9,
        top_k: 40
      )
    end

    it "returns a hash with all the model attributes" do
      hash = model.to_h

      expect(hash[:name]).to eq("models/gemini-1.5-pro")
      expect(hash[:id]).to eq("gemini-1.5-pro")
      expect(hash[:base_model_id]).to eq("gemini-1.5-pro")
      expect(hash[:version]).to eq("1.5")
      expect(hash[:display_name]).to eq("Gemini 1.5 Pro")
      expect(hash[:description]).to eq("A powerful model")
      expect(hash[:input_token_limit]).to eq(30720)
      expect(hash[:output_token_limit]).to eq(8192)
      expect(hash[:supported_generation_methods]).to eq(["generateContent", "streamGenerateContent"])
      expect(hash[:temperature]).to eq(0.7)
      expect(hash[:max_temperature]).to eq(1.0)
      expect(hash[:top_p]).to eq(0.9)
      expect(hash[:top_k]).to eq(40)
    end
  end

  describe "#to_json" do
    subject(:model) do
      described_class.new(
        name: "models/gemini-1.5-pro",
        display_name: "Gemini 1.5 Pro"
      )
    end

    it "returns a JSON string representation of the model" do
      json = model.to_json
      parsed = JSON.parse(json)

      expect(parsed["name"]).to eq("models/gemini-1.5-pro")
      expect(parsed["display_name"]).to eq("Gemini 1.5 Pro")
    end
  end

  describe "#id" do
    it "returns the last part of the name path" do
      model = described_class.new(name: "models/gemini-1.5-pro")
      expect(model.id).to eq("gemini-1.5-pro")
    end

    it "returns nil when name is not set" do
      model = described_class.new
      expect(model.id).to be_nil
    end
  end
end
