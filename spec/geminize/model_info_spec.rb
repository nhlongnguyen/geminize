# frozen_string_literal: true

RSpec.describe Geminize::ModelInfo do
  let(:client) { instance_double(Geminize::Client) }
  let(:model_info) { described_class.new(client) }

  describe "#list_models" do
    let(:models_response) do
      {
        "models" => [
          {
            "name" => "models/gemini-2.0-flash",
            "baseModelId" => "gemini-2.0-flash",
            "version" => "1.5",
            "displayName" => "Gemini 1.5 Pro",
            "description" => "A powerful multimodal model for generating text and analyzing images",
            "supportedGenerationMethods" => ["generateContent", "streamGenerateContent"],
            "inputTokenLimit" => 30720,
            "outputTokenLimit" => 8192,
            "temperature" => 0.7,
            "maxTemperature" => 1.0,
            "topP" => 0.9,
            "topK" => 40
          },
          {
            "name" => "models/gemini-1.5-flash",
            "baseModelId" => "gemini-1.5-flash",
            "version" => "1.5",
            "displayName" => "Gemini 1.5 Flash",
            "description" => "A fast and efficient text generation model",
            "supportedGenerationMethods" => ["generateContent", "streamGenerateContent"],
            "inputTokenLimit" => 30720,
            "outputTokenLimit" => 2048,
            "temperature" => 0.7,
            "maxTemperature" => 1.0,
            "topP" => 0.9,
            "topK" => 40
          },
          {
            "name" => "models/embedding-001",
            "baseModelId" => "embedding-001",
            "version" => "001",
            "displayName" => "Embedding-001",
            "description" => "A model for creating text embeddings for semantic search",
            "supportedGenerationMethods" => ["embedContent"],
            "inputTokenLimit" => 2048,
            "temperature" => 0.0
          }
        ],
        "nextPageToken" => "abc123token"
      }
    end

    let(:next_page_response) do
      {
        "models" => [
          {
            "name" => "models/gemini-1.0-pro",
            "baseModelId" => "gemini-1.0-pro",
            "version" => "1.0",
            "displayName" => "Gemini 1.0 Pro",
            "description" => "An earlier version of the Gemini model",
            "supportedGenerationMethods" => ["generateContent"],
            "inputTokenLimit" => 8192,
            "outputTokenLimit" => 2048
          }
        ]
      }
    end

    before do
      # Allow general calls with proper responses
      allow(client).to receive(:get).with("models", hash_including({})).and_return(models_response)
      allow(client).to receive(:get).with("models", hash_including(pageToken: "abc123token")).and_return(next_page_response)

      # Stub specific parameter combinations
      allow(client).to receive(:get).with("models", {pageToken: nil}).and_return(models_response)
      allow(client).to receive(:get).with("models", {pageSize: 10, pageToken: nil}).and_return(models_response)
      allow(client).to receive(:get).with("models", {pageSize: 50, pageToken: nil}).and_return(models_response)
    end

    it "returns a ModelList with models from the API" do
      model_list = model_info.list_models

      expect(model_list).to be_a(Geminize::Models::ModelList)
      expect(model_list.size).to eq(3)
      expect(model_list.next_page_token).to eq("abc123token")

      # Check that models are properly extracted
      model = model_list.find_by_name("models/gemini-2.0-flash")
      expect(model).not_to be_nil
      expect(model.display_name).to eq("Gemini 1.5 Pro")
      expect(model.base_model_id).to eq("gemini-2.0-flash")
      expect(model.supported_generation_methods).to contain_exactly("generateContent", "streamGenerateContent")
      expect(model.input_token_limit).to eq(30720)
      expect(model.output_token_limit).to eq(8192)
    end

    it "accepts pagination parameters" do
      expect(client).to receive(:get).with("models", {pageSize: 10, pageToken: nil}).and_return(models_response)
      model_list = model_info.list_models(page_size: 10, page_token: nil)
      expect(model_list.size).to eq(3)
    end

    it "caches the results with the pagination parameters" do
      # First call should query the API
      model_info.list_models(page_size: 10, page_token: nil)

      # Second call with the same parameters should use the cache
      expect(client).not_to receive(:get).with("models", {pageSize: 10, pageToken: nil})
      model_info.list_models(page_size: 10, page_token: nil)

      # Call with different parameters should query the API
      expect(client).to receive(:get).with("models", {pageToken: "abc123token"}).and_return(next_page_response)
      model_info.list_models(page_token: "abc123token")
    end

    it "refreshes the cache when forced" do
      # First call should query the API
      model_info.list_models(page_size: 10, page_token: nil)

      # Second call with force_refresh should query the API again
      expect(client).to receive(:get).with("models", {pageSize: 10, pageToken: nil}).and_return(models_response)
      model_info.list_models(page_size: 10, page_token: nil, force_refresh: true)
    end
  end

  describe "#list_all_models" do
    let(:first_page) do
      {
        "models" => [
          {
            "name" => "models/gemini-2.0-flash",
            "baseModelId" => "gemini-2.0-flash",
            "displayName" => "Gemini 1.5 Pro"
          },
          {
            "name" => "models/gemini-1.5-flash",
            "baseModelId" => "gemini-1.5-flash",
            "displayName" => "Gemini 1.5 Flash"
          }
        ],
        "nextPageToken" => "page2token"
      }
    end

    let(:second_page) do
      {
        "models" => [
          {
            "name" => "models/embedding-001",
            "baseModelId" => "embedding-001",
            "displayName" => "Embedding-001"
          }
        ]
      }
    end

    before do
      allow(client).to receive(:get).with("models", hash_including(pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageToken: "page2token")).and_return(second_page)
      allow(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: "page2token")).and_return(second_page)
    end

    it "fetches and combines all pages of models" do
      all_models = model_info.list_all_models

      expect(all_models).to be_a(Geminize::Models::ModelList)
      expect(all_models.size).to eq(3)
      expect(all_models.next_page_token).to be_nil
      expect(all_models.map { |m| m.name }).to contain_exactly(
        "models/gemini-2.0-flash", "models/gemini-1.5-flash", "models/embedding-001"
      )
    end

    it "caches the combined results" do
      # First call should query the API
      model_info.list_all_models

      # Second call should use the cache
      expect(client).not_to receive(:get)
      model_info.list_all_models
    end

    it "refreshes the cache when forced" do
      # First call should query the API
      model_info.list_all_models

      # Second call with force_refresh should query the API again
      expect(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: nil)).and_return(first_page)
      expect(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: "page2token")).and_return(second_page)
      model_info.list_all_models(force_refresh: true)
    end
  end

  describe "#get_model" do
    let(:model_name) { "gemini-2.0-flash" }
    let(:full_model_name) { "models/gemini-2.0-flash" }
    let(:model_response) do
      {
        "name" => "models/gemini-2.0-flash",
        "baseModelId" => "gemini-2.0-flash",
        "version" => "1.5",
        "displayName" => "Gemini 1.5 Pro",
        "description" => "A powerful multimodal model for generating text and analyzing images",
        "supportedGenerationMethods" => ["generateContent", "streamGenerateContent"],
        "inputTokenLimit" => 30720,
        "outputTokenLimit" => 8192,
        "temperature" => 0.7,
        "maxTemperature" => 1.0,
        "topP" => 0.9,
        "topK" => 40
      }
    end

    before do
      allow(client).to receive(:get).with(full_model_name).and_return(model_response)
    end

    it "returns a Model with details from the API" do
      model = model_info.get_model(model_name)

      expect(model).to be_a(Geminize::Models::Model)
      expect(model.name).to eq(full_model_name)
      expect(model.id).to eq(model_name)
      expect(model.base_model_id).to eq("gemini-2.0-flash")
      expect(model.version).to eq("1.5")
      expect(model.display_name).to eq("Gemini 1.5 Pro")
      expect(model.description).to eq("A powerful multimodal model for generating text and analyzing images")
      expect(model.input_token_limit).to eq(30720)
      expect(model.output_token_limit).to eq(8192)
      expect(model.supported_generation_methods).to contain_exactly("generateContent", "streamGenerateContent")
      expect(model.temperature).to eq(0.7)
      expect(model.max_temperature).to eq(1.0)
      expect(model.top_p).to eq(0.9)
      expect(model.top_k).to eq(40)
    end

    it "prepends 'models/' if not provided" do
      expect(client).to receive(:get).with(full_model_name).and_return(model_response)
      model_info.get_model(model_name)
    end

    it "uses the provided name if it already starts with 'models/'" do
      expect(client).to receive(:get).with(full_model_name).and_return(model_response)
      model_info.get_model(full_model_name)
    end

    it "caches the results" do
      # First call should query the API
      model_info.get_model(model_name)

      # Second call should use the cache
      expect(client).not_to receive(:get)
      model_info.get_model(model_name)
    end

    it "refreshes the cache when forced" do
      # First call should query the API
      model_info.get_model(model_name)

      # Second call with force_refresh should query the API again
      expect(client).to receive(:get).with(full_model_name).and_return(model_response)
      model_info.get_model(model_name, force_refresh: true)
    end

    context "when the model is not found" do
      before do
        allow(client).to receive(:get).with("models/nonexistent-model").and_raise(
          Geminize::NotFoundError.new("Model not found", "NOT_FOUND", 404)
        )
      end

      it "raises a NotFoundError with a descriptive message" do
        expect { model_info.get_model("nonexistent-model") }.to raise_error(
          Geminize::NotFoundError, /Model 'models\/nonexistent-model' not found/
        )
      end
    end
  end

  describe "#get_models_by_method" do
    let(:model1) do
      Geminize::Models::Model.new(
        name: "models/gemini-2.0-flash",
        supported_generation_methods: ["generateContent", "embedContent"]
      )
    end

    let(:model2) do
      Geminize::Models::Model.new(
        name: "models/gemini-1.5-flash",
        supported_generation_methods: ["generateContent"]
      )
    end

    let(:model3) do
      Geminize::Models::Model.new(
        name: "models/embedding-001",
        supported_generation_methods: ["embedContent"]
      )
    end

    let(:all_models) { Geminize::Models::ModelList.new([model1, model2, model3]) }

    before do
      allow(model_info).to receive(:list_all_models).and_return(all_models)
    end

    it "returns models that support the specified method" do
      result = model_info.get_models_by_method("embedContent")

      expect(result).to be_a(Geminize::Models::ModelList)
      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model3)
    end

    it "returns an empty list when no models support the method" do
      result = model_info.get_models_by_method("unknownMethod")

      expect(result).to be_a(Geminize::Models::ModelList)
      expect(result).to be_empty
    end

    it "passes the force_refresh parameter to list_all_models" do
      expect(model_info).to receive(:list_all_models).with(force_refresh: true).and_return(all_models)
      model_info.get_models_by_method("generateContent", force_refresh: true)
    end
  end

  describe "#get_models_by_base_id" do
    let(:model1) do
      Geminize::Models::Model.new(
        name: "models/gemini-2.0-flash-001",
        base_model_id: "gemini-2.0-flash"
      )
    end

    let(:model2) do
      Geminize::Models::Model.new(
        name: "models/gemini-2.0-flash-002",
        base_model_id: "gemini-2.0-flash"
      )
    end

    let(:model3) do
      Geminize::Models::Model.new(
        name: "models/embedding-001",
        base_model_id: "embedding"
      )
    end

    let(:all_models) { Geminize::Models::ModelList.new([model1, model2, model3]) }

    before do
      allow(model_info).to receive(:list_all_models).and_return(all_models)
    end

    it "returns models with the specified base model ID" do
      result = model_info.get_models_by_base_id("gemini-2.0-flash")

      expect(result).to be_a(Geminize::Models::ModelList)
      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model2)
    end

    it "returns an empty list when no models match the base model ID" do
      result = model_info.get_models_by_base_id("nonexistent-base-id")

      expect(result).to be_a(Geminize::Models::ModelList)
      expect(result).to be_empty
    end

    it "passes the force_refresh parameter to list_all_models" do
      expect(model_info).to receive(:list_all_models).with(force_refresh: true).and_return(all_models)
      model_info.get_models_by_base_id("gemini-2.0-flash", force_refresh: true)
    end
  end

  describe "#clear_cache" do
    let(:models_response) { {"models" => []} }
    let(:first_page) { {"models" => [], "nextPageToken" => "abc123"} }
    let(:second_page) { {"models" => []} }
    let(:model_response) { {"name" => "models/gemini-2.0-flash", "displayName" => "Gemini 1.5 Pro"} }

    before do
      # Set up stubs for all the API calls that might happen
      allow(client).to receive(:get).with("models", hash_including({})).and_return(models_response)
      allow(client).to receive(:get).with("models", hash_including(pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageToken: "abc123")).and_return(second_page)
      allow(client).to receive(:get).with("models/gemini-2.0-flash").and_return(model_response)

      # Populate the cache
      model_info.list_models
      model_info.list_all_models
      model_info.get_model("gemini-2.0-flash")
    end

    it "clears all cached model information" do
      # All should use cache initially
      expect(client).not_to receive(:get)
      model_info.list_models
      model_info.list_all_models
      model_info.get_model("gemini-2.0-flash")

      # Reset the expectations after checking cache usage
      RSpec::Mocks.space.proxy_for(client).reset

      # Clear the cache
      model_info.clear_cache

      # After cache clearing, separate each API call test to avoid ordering issues
      expect(client).to receive(:get).with("models", hash_including(pageToken: nil)).and_return(models_response)
      model_info.list_models

      # Reset expectations
      RSpec::Mocks.space.proxy_for(client).reset
      allow(client).to receive(:get).with("models", hash_including({})).and_return(models_response)
      allow(client).to receive(:get).with("models", hash_including(pageToken: nil)).and_return(first_page)

      expect(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: nil)).and_return(first_page)
      expect(client).to receive(:get).with("models", hash_including(pageToken: "abc123")).and_return(second_page)
      model_info.list_all_models

      # Reset expectations
      RSpec::Mocks.space.proxy_for(client).reset
      allow(client).to receive(:get).with("models", hash_including({})).and_return(models_response)
      allow(client).to receive(:get).with("models", hash_including(pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageSize: 50, pageToken: nil)).and_return(first_page)
      allow(client).to receive(:get).with("models", hash_including(pageToken: "abc123")).and_return(second_page)

      expect(client).to receive(:get).with("models/gemini-2.0-flash").and_return(model_response)
      model_info.get_model("gemini-2.0-flash")
    end
  end
end
