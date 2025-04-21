# frozen_string_literal: true

RSpec.describe Geminize::Configuration do
  let(:api_key) { "test-api-key" }
  let(:api_version) { "v2" }
  let(:default_model) { "test-model" }

  # Reset singleton before each test to ensure clean state
  before do
    described_class.instance.reset!
  end

  describe "#initialize" do
    context "with environment variables" do
      around do |example|
        ClimateControl.modify GEMINI_API_KEY: api_key do
          described_class.instance.reset!
          example.run
        end
      end

      it "loads API key from environment variable" do
        config = described_class.instance
        expect(config.api_key).to eq(api_key)
      end
    end

    it "sets default values" do
      config = described_class.instance
      expect(config.api_version).to eq(Geminize::Configuration::DEFAULT_API_VERSION)
      expect(config.default_model).to eq(Geminize::Configuration::DEFAULT_MODEL)
      expect(config.timeout).to eq(Geminize::Configuration::DEFAULT_TIMEOUT)
      expect(config.open_timeout).to eq(Geminize::Configuration::DEFAULT_OPEN_TIMEOUT)
      expect(config.log_requests).to be false
    end
  end

  describe "attributes" do
    it "allows setting and getting attributes" do
      config = described_class.instance
      config.api_key = api_key
      config.api_version = api_version
      config.default_model = default_model
      config.timeout = 60
      config.open_timeout = 20
      config.log_requests = true

      expect(config.api_key).to eq(api_key)
      expect(config.api_version).to eq(api_version)
      expect(config.default_model).to eq(default_model)
      expect(config.timeout).to eq(60)
      expect(config.open_timeout).to eq(20)
      expect(config.log_requests).to be true
    end
  end

  describe "#reset!" do
    it "resets all values to defaults" do
      config = described_class.instance
      config.api_key = api_key
      config.api_version = api_version
      config.default_model = default_model
      config.timeout = 60
      config.open_timeout = 20
      config.log_requests = true

      config.reset!

      expect(config.api_version).to eq(Geminize::Configuration::DEFAULT_API_VERSION)
      expect(config.default_model).to eq(Geminize::Configuration::DEFAULT_MODEL)
      expect(config.timeout).to eq(Geminize::Configuration::DEFAULT_TIMEOUT)
      expect(config.open_timeout).to eq(Geminize::Configuration::DEFAULT_OPEN_TIMEOUT)
      expect(config.log_requests).to be false
    end
  end

  describe "#api_base_url" do
    it "returns the API base URL" do
      config = described_class.instance
      expect(config.api_base_url).to eq(Geminize::Configuration::API_BASE_URL)
    end
  end

  describe "#validate!" do
    let(:config) { described_class.instance }

    before do
      config.reset!
    end

    it "returns true when configuration is valid" do
      config.api_key = api_key
      expect(config.validate!).to be true
    end

    it "raises ConfigurationError when API key is missing" do
      config.api_key = nil
      expect { config.validate! }.to raise_error(Geminize::ConfigurationError, "API key must be set")
    end

    it "raises ConfigurationError when API key is empty" do
      config.api_key = ""
      expect { config.validate! }.to raise_error(Geminize::ConfigurationError, "API key must be set")
    end

    it "raises ConfigurationError when API version is missing" do
      config.api_key = api_key
      config.api_version = nil
      expect { config.validate! }.to raise_error(Geminize::ConfigurationError, "API version must be set")
    end

    it "raises ConfigurationError when API version is empty" do
      config.api_key = api_key
      config.api_version = ""
      expect { config.validate! }.to raise_error(Geminize::ConfigurationError, "API version must be set")
    end
  end
end
