# frozen_string_literal: true

RSpec.describe Geminize::ModelInfo do
  let(:client) { instance_double(Geminize::Client) }
  let(:model_info) { described_class.new(client) }

  describe "#list_models" do
    let(:models_response) do
      {
        "models" => [
          {
            "name" => "models/gemini-1.5-pro",
            "displayName" => "Gemini 1.5 Pro",
            "description" => "A powerful multimodal model for generating text and analyzing images",
            "supportedGenerationMethods" => ["generateText", "generateContent"],
            "inputTokenLimit" => 30720,
            "outputTokenLimit" => 8192
          },
          {
            "name" => "models/gemini-1.5-flash",
            "displayName" => "Gemini 1.5 Flash",
            "description" => "A fast and efficient text generation model",
            "supportedGenerationMethods" => ["generateText"],
            "inputTokenLimit" => 30720,
            "outputTokenLimit" => 2048
          },
          {
            "name" => "models/embedding-001",
            "displayName" => "Embedding-001",
            "description" => "A model for creating text embeddings for semantic search",
            "supportedGenerationMethods" => ["embedContent"],
            "inputTokenLimit" => 2048
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with("models").and_return(models_response)
    end

    it "returns a ModelList with models from the API" do
      model_list = model_info.list_models

      expect(model_list).to be_a(Geminize::Models::ModelList)
      expect(model_list.size).to eq(3)

      # Check that models are properly extracted
      model_names = model_list.map(&:name)
      expect(model_names).to contain_exactly("Gemini 1.5 Pro", "Gemini 1.5 Flash", "Embedding-001")
    end

    it "caches the results" do
      # First call should query the API
      model_info.list_models

      # Second call should use the cache
      expect(client).not_to receive(:get)
      model_info.list_models
    end

    it "refreshes the cache when forced" do
      # First call should query the API
      model_info.list_models

      # Second call with force_refresh should query the API again
      expect(client).to receive(:get).with("models").and_return(models_response)
      model_info.list_models(force_refresh: true)
    end
  end

  describe "#get_model" do
    let(:model_id) { "gemini-1.5-pro" }
    let(:model_response) do
      {
        "name" => "models/gemini-1.5-pro",
        "displayName" => "Gemini 1.5 Pro",
        "description" => "A powerful multimodal model for generating text and analyzing images",
        "supportedGenerationMethods" => ["generateText", "generateContent"],
        "inputTokenLimit" => 30720,
        "outputTokenLimit" => 8192,
        "inputSetting" => {
          "supportMultiModal" => true
        }
      }
    end

    before do
      allow(client).to receive(:get).with("models/#{model_id}").and_return(model_response)
    end

    it "returns a Model with details from the API" do
      model = model_info.get_model(model_id)

      expect(model).to be_a(Geminize::Models::Model)
      expect(model.id).to eq(model_id)
      expect(model.name).to eq("Gemini 1.5 Pro")
      expect(model.description).to eq("A powerful multimodal model for generating text and analyzing images")
      expect(model.capabilities).to include("text", "vision")
      expect(model.limitations).to include(input_token_limit: 30720, output_token_limit: 8192)
    end

    it "caches the results" do
      # First call should query the API
      model_info.get_model(model_id)

      # Second call should use the cache
      expect(client).not_to receive(:get)
      model_info.get_model(model_id)
    end

    it "refreshes the cache when forced" do
      # First call should query the API
      model_info.get_model(model_id)

      # Second call with force_refresh should query the API again
      expect(client).to receive(:get).with("models/#{model_id}").and_return(model_response)
      model_info.get_model(model_id, force_refresh: true)
    end

    context "when the model is not found" do
      before do
        allow(client).to receive(:get).with("models/nonexistent-model").and_raise(
          Geminize::NotFoundError.new("Model not found", "NOT_FOUND", 404)
        )
      end

      it "raises a NotFoundError with a descriptive message" do
        expect { model_info.get_model("nonexistent-model") }.to raise_error(
          Geminize::NotFoundError, /Model 'nonexistent-model' not found/
        )
      end
    end
  end

  describe "#clear_cache" do
    let(:models_response) { { "models" => [] } }
    let(:model_response) { { "name" => "models/gemini-1.5-pro", "displayName" => "Gemini 1.5 Pro" } }

    before do
      allow(client).to receive(:get).with("models").and_return(models_response)
      allow(client).to receive(:get).with("models/gemini-1.5-pro").and_return(model_response)

      # Populate the cache
      model_info.list_models
      model_info.get_model("gemini-1.5-pro")

      # Reset the expectations after populating the cache
      RSpec::Mocks.space.proxy_for(client).reset
    end

    it "clears all cached model information" do
      # Both should use cache initially
      expect(client).not_to receive(:get)
      model_info.list_models
      model_info.get_model("gemini-1.5-pro")

      # Reset the expectations after checking cache usage
      RSpec::Mocks.space.proxy_for(client).reset

      # Clear the cache
      model_info.clear_cache

      # Both should make API calls again
      expect(client).to receive(:get).with("models").and_return(models_response)
      expect(client).to receive(:get).with("models/gemini-1.5-pro").and_return(model_response)

      model_info.list_models
      model_info.get_model("gemini-1.5-pro")
    end
  end
end
