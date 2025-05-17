# frozen_string_literal: true

RSpec.describe "Geminize Models API Integration" do
  before(:each) do
    # Mock ModelInfo to avoid actual API calls
    @mock_model_info = instance_double(Geminize::ModelInfo)
    allow(Geminize::ModelInfo).to receive(:new).and_return(@mock_model_info)

    # Mock configuration validation to avoid errors
    allow(Geminize).to receive(:validate_configuration!).and_return(true)
  end

  describe "Geminize.list_models" do
    let(:model_list) do
      Geminize::Models::ModelList.new([
        Geminize::Models::Model.new(
          name: "models/gemini-2.0-flash",
          display_name: "Gemini 1.5 Pro"
        )
      ])
    end

    it "calls ModelInfo#list_models with the correct parameters" do
      expect(@mock_model_info).to receive(:list_models).with(
        page_size: 10,
        page_token: "token123",
        force_refresh: true
      ).and_return(model_list)

      result = Geminize.list_models(
        page_size: 10,
        page_token: "token123",
        force_refresh: true
      )

      expect(result).to eq(model_list)
    end

    it "passes client options to ModelInfo.new" do
      client_options = {timeout: 30}
      expect(Geminize::ModelInfo).to receive(:new).with(nil, client_options).and_return(@mock_model_info)
      expect(@mock_model_info).to receive(:list_models).and_return(model_list)

      Geminize.list_models(client_options: client_options)
    end
  end

  describe "Geminize.list_all_models" do
    let(:all_models) do
      Geminize::Models::ModelList.new([
        Geminize::Models::Model.new(name: "models/model1"),
        Geminize::Models::Model.new(name: "models/model2")
      ])
    end

    it "calls ModelInfo#list_all_models with force_refresh parameter" do
      expect(@mock_model_info).to receive(:list_all_models).with(force_refresh: true).and_return(all_models)
      result = Geminize.list_all_models(force_refresh: true)
      expect(result).to eq(all_models)
    end

    it "passes client options to ModelInfo.new" do
      client_options = {timeout: 30}
      expect(Geminize::ModelInfo).to receive(:new).with(nil, client_options).and_return(@mock_model_info)
      expect(@mock_model_info).to receive(:list_all_models).and_return(all_models)

      Geminize.list_all_models(client_options: client_options)
    end
  end

  describe "Geminize.get_model" do
    let(:model) do
      Geminize::Models::Model.new(
        name: "models/gemini-2.0-flash",
        display_name: "Gemini 1.5 Pro"
      )
    end

    it "calls ModelInfo#get_model with the correct parameters" do
      expect(@mock_model_info).to receive(:get_model).with(
        "gemini-2.0-flash",
        force_refresh: true
      ).and_return(model)

      result = Geminize.get_model("gemini-2.0-flash", force_refresh: true)
      expect(result).to eq(model)
    end

    it "passes client options to ModelInfo.new" do
      client_options = {timeout: 30}
      expect(Geminize::ModelInfo).to receive(:new).with(nil, client_options).and_return(@mock_model_info)
      expect(@mock_model_info).to receive(:get_model).and_return(model)

      Geminize.get_model("gemini-2.0-flash", client_options: client_options)
    end
  end

  describe "Geminize.get_models_by_method" do
    let(:model_list) do
      Geminize::Models::ModelList.new([
        Geminize::Models::Model.new(
          name: "models/model1",
          supported_generation_methods: ["embedContent"]
        )
      ])
    end

    it "calls ModelInfo#get_models_by_method with the correct parameters" do
      expect(@mock_model_info).to receive(:get_models_by_method).with(
        "embedContent",
        force_refresh: true
      ).and_return(model_list)

      result = Geminize.get_models_by_method("embedContent", force_refresh: true)
      expect(result).to eq(model_list)
    end

    it "passes client options to ModelInfo.new" do
      client_options = {timeout: 30}
      expect(Geminize::ModelInfo).to receive(:new).with(nil, client_options).and_return(@mock_model_info)
      expect(@mock_model_info).to receive(:get_models_by_method).and_return(model_list)

      Geminize.get_models_by_method("embedContent", client_options: client_options)
    end
  end

  describe "Geminize filtering helper methods" do
    let(:models) do
      Geminize::Models::ModelList.new([
        Geminize::Models::Model.new(
          name: "models/gemini-2.0-flash",
          supported_generation_methods: ["generateContent", "streamGenerateContent", "embedContent"]
        ),
        Geminize::Models::Model.new(
          name: "models/gemini-1.5-flash",
          supported_generation_methods: ["generateContent", "streamGenerateContent"]
        ),
        Geminize::Models::Model.new(
          name: "models/embedding-001",
          supported_generation_methods: ["embedContent"]
        ),
        Geminize::Models::Model.new(
          name: "models/gemini-chat",
          supported_generation_methods: ["generateMessage"]
        )
      ])
    end

    before do
      allow(@mock_model_info).to receive(:list_all_models).and_return(models)
    end

    describe "Geminize.get_content_generation_models" do
      it "filters models that support content generation" do
        result = Geminize.get_content_generation_models
        expect(result.size).to eq(2)
        expect(result.map(&:name)).to contain_exactly(
          "models/gemini-2.0-flash",
          "models/gemini-1.5-flash"
        )
      end
    end

    describe "Geminize.get_embedding_models" do
      it "filters models that support embedding generation" do
        result = Geminize.get_embedding_models
        expect(result.size).to eq(2)
        expect(result.map(&:name)).to contain_exactly(
          "models/gemini-2.0-flash",
          "models/embedding-001"
        )
      end
    end

    describe "Geminize.get_chat_models" do
      it "filters models that support chat generation" do
        result = Geminize.get_chat_models
        expect(result.size).to eq(1)
        expect(result.first.name).to eq("models/gemini-chat")
      end
    end

    describe "Geminize.get_streaming_models" do
      it "filters models that support streaming generation" do
        result = Geminize.get_streaming_models
        expect(result.size).to eq(2)
        expect(result.map(&:name)).to contain_exactly(
          "models/gemini-2.0-flash",
          "models/gemini-1.5-flash"
        )
      end
    end
  end
end
