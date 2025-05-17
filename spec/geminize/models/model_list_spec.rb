# frozen_string_literal: true

RSpec.describe Geminize::Models::ModelList do
  let(:model1) do
    Geminize::Models::Model.new(
      name: "models/gemini-2.0-flash",
      base_model_id: "gemini-2.0-flash",
      version: "1.5",
      display_name: "Gemini 1.5 Pro",
      input_token_limit: 30720,
      output_token_limit: 8192,
      supported_generation_methods: ["generateContent", "streamGenerateContent", "embedContent"]
    )
  end

  let(:model2) do
    Geminize::Models::Model.new(
      name: "models/gemini-1.5-flash",
      base_model_id: "gemini-1.5-flash",
      version: "1.5",
      display_name: "Gemini 1.5 Flash",
      input_token_limit: 20000,
      output_token_limit: 4096,
      supported_generation_methods: ["generateContent", "streamGenerateContent"]
    )
  end

  let(:model3) do
    Geminize::Models::Model.new(
      name: "models/embedding-001",
      base_model_id: "embedding-001",
      version: "001",
      display_name: "Text Embeddings",
      input_token_limit: 2048,
      output_token_limit: nil,
      supported_generation_methods: ["embedContent"]
    )
  end

  let(:models) { [model1, model2, model3] }
  let(:next_page_token) { "abc123token" }

  subject(:model_list) { described_class.new(models) }
  subject(:paginated_list) { described_class.new(models, next_page_token) }

  describe "#initialize" do
    it "initializes with an array of models" do
      expect(model_list.models).to eq(models)
      expect(model_list.next_page_token).to be_nil
    end

    it "initializes with an empty array when no models are provided" do
      empty_list = described_class.new
      expect(empty_list.models).to eq([])
      expect(empty_list.next_page_token).to be_nil
    end

    it "initializes with models and a next page token" do
      expect(paginated_list.models).to eq(models)
      expect(paginated_list.next_page_token).to eq(next_page_token)
    end
  end

  describe "#add" do
    let(:new_model) do
      Geminize::Models::Model.new(
        name: "models/gemini-2.0-pro",
        display_name: "Gemini 2.0 Pro"
      )
    end

    it "adds a model to the list" do
      result = model_list.add(new_model)

      expect(result).to eq(model_list) # Returns self for chaining
      expect(model_list.models).to include(new_model)
      expect(model_list.size).to eq(4)
    end
  end

  describe "#find_by_name" do
    it "returns the model with the matching name" do
      result = model_list.find_by_name("models/gemini-2.0-flash")
      expect(result).to eq(model1)
    end

    it "returns nil when no model matches the name" do
      result = model_list.find_by_name("models/nonexistent-model")
      expect(result).to be_nil
    end
  end

  describe "#find_by_id" do
    it "returns the model with the matching ID" do
      result = model_list.find_by_id("gemini-2.0-flash")
      expect(result).to eq(model1)
    end

    it "returns nil when no model matches the ID" do
      result = model_list.find_by_id("nonexistent-model")
      expect(result).to be_nil
    end
  end

  describe "#filter_by_method" do
    it "returns a new ModelList with models supporting the specified method" do
      result = model_list.filter_by_method("embedContent")

      expect(result).to be_a(described_class)
      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model3)
    end

    it "returns an empty ModelList when no models support the method" do
      result = model_list.filter_by_method("unknownMethod")

      expect(result).to be_a(described_class)
      expect(result).to be_empty
    end

    it "creates a new list without a next_page_token" do
      result = paginated_list.filter_by_method("generateContent")
      expect(result.next_page_token).to be_nil
    end
  end

  describe "method-specific filters" do
    describe "#content_generation_models" do
      it "returns models that support generateContent" do
        result = model_list.content_generation_models
        expect(result.size).to eq(2)
        expect(result.models).to contain_exactly(model1, model2)
      end
    end

    describe "#streaming_models" do
      it "returns models that support streamGenerateContent" do
        result = model_list.streaming_models
        expect(result.size).to eq(2)
        expect(result.models).to contain_exactly(model1, model2)
      end
    end

    describe "#embedding_models" do
      it "returns models that support embedContent" do
        result = model_list.embedding_models
        expect(result.size).to eq(2)
        expect(result.models).to contain_exactly(model1, model3)
      end
    end

    describe "#chat_models" do
      it "returns models that support generateMessage" do
        # Create a model with chat support
        chat_model = Geminize::Models::Model.new(
          name: "models/gemini-chat",
          supported_generation_methods: ["generateMessage"]
        )
        chat_list = described_class.new([model1, model2, model3, chat_model])

        result = chat_list.chat_models
        expect(result.size).to eq(1)
        expect(result.first).to eq(chat_model)
      end

      it "returns an empty list when no models support chat" do
        result = model_list.chat_models
        expect(result).to be_empty
      end
    end
  end

  describe "#filter_by_version" do
    it "filters models by version" do
      result = model_list.filter_by_version("1.5")

      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model2)
    end
  end

  describe "#filter_by_display_name" do
    it "filters models by display name using a string pattern" do
      result = model_list.filter_by_display_name("Flash")

      expect(result.size).to eq(1)
      expect(result.first).to eq(model2)
    end

    it "filters models by display name using a regexp" do
      result = model_list.filter_by_display_name(/Gemini/)

      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model2)
    end
  end

  describe "#filter_by_base_model_id" do
    it "filters models by base model ID" do
      result = model_list.filter_by_base_model_id("gemini-2.0-flash")

      expect(result.size).to eq(1)
      expect(result.first).to eq(model1)
    end

    it "returns an empty list when no models match the base model ID" do
      result = model_list.filter_by_base_model_id("nonexistent-base-id")
      expect(result).to be_empty
    end
  end

  describe "#filter_by_min_input_tokens" do
    it "filters models by minimum input token limit" do
      result = model_list.filter_by_min_input_tokens(25000)

      expect(result.size).to eq(1)
      expect(result.first).to eq(model1)
    end

    it "handles models with nil input token limit" do
      model_with_nil = Geminize::Models::Model.new(
        name: "models/test-model",
        input_token_limit: nil
      )
      list_with_nil = described_class.new([model1, model2, model3, model_with_nil])

      result = list_with_nil.filter_by_min_input_tokens(1000)
      expect(result.size).to eq(3)
      expect(result.models).to contain_exactly(model1, model2, model3)
    end
  end

  describe "#filter_by_min_output_tokens" do
    it "filters models by minimum output token limit" do
      result = model_list.filter_by_min_output_tokens(5000)

      expect(result.size).to eq(1)
      expect(result.first).to eq(model1)
    end

    it "handles models with nil output token limit" do
      result = model_list.filter_by_min_output_tokens(1)
      expect(result.size).to eq(2)
      expect(result.models).to contain_exactly(model1, model2)
    end
  end

  describe ".from_api_data" do
    let(:api_data) do
      {
        "models" => [
          {
            "name" => "models/gemini-2.0-flash",
            "baseModelId" => "gemini-2.0-flash",
            "version" => "1.5",
            "displayName" => "Gemini 1.5 Pro"
          },
          {
            "name" => "models/embedding-001",
            "baseModelId" => "embedding-001",
            "version" => "001",
            "displayName" => "Text Embeddings"
          }
        ],
        "nextPageToken" => "abc123token"
      }
    end

    it "creates a ModelList from API response data with pagination" do
      allow(Geminize::Models::Model).to receive(:from_api_data) do |data|
        Geminize::Models::Model.new(
          name: data["name"],
          base_model_id: data["baseModelId"],
          version: data["version"],
          display_name: data["displayName"]
        )
      end

      result = described_class.from_api_data(api_data)

      expect(result).to be_a(described_class)
      expect(result.size).to eq(2)
      expect(result.map(&:name)).to contain_exactly("models/gemini-2.0-flash", "models/embedding-001")
      expect(result.next_page_token).to eq("abc123token")
    end

    it "creates a ModelList without pagination when nextPageToken is not provided" do
      api_data_without_token = api_data.dup
      api_data_without_token.delete("nextPageToken")

      allow(Geminize::Models::Model).to receive(:from_api_data) do |data|
        Geminize::Models::Model.new(
          name: data["name"],
          display_name: data["displayName"]
        )
      end

      result = described_class.from_api_data(api_data_without_token)

      expect(result.next_page_token).to be_nil
    end
  end

  describe "#has_more_pages?" do
    it "returns true when next_page_token is present" do
      expect(paginated_list.has_more_pages?).to be true
    end

    it "returns false when next_page_token is nil" do
      expect(model_list.has_more_pages?).to be false
    end

    it "returns false when next_page_token is empty" do
      list_with_empty_token = described_class.new(models, "")
      expect(list_with_empty_token.has_more_pages?).to be false
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
      expect(parsed.first["name"]).to eq("models/gemini-2.0-flash")
    end
  end

  describe "enumerable methods" do
    it "implements each method" do
      collected_models = []
      model_list.each { |model| collected_models << model }

      expect(collected_models).to eq(models)
    end

    it "supports other enumerable methods" do
      result = model_list.map { |model| model.id }
      expect(result).to eq(["gemini-2.0-flash", "gemini-1.5-flash", "embedding-001"])

      result = model_list.select { |model| model.id.start_with?("gemini") }
      expect(result.map(&:id)).to eq(["gemini-2.0-flash", "gemini-1.5-flash"])
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
