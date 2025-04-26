# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive information
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }

  # Set default record mode - record once and replay afterwards
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

RSpec.describe Geminize do
  it "has a version number" do
    expect(Geminize::VERSION).not_to be nil
  end

  # Reset the configuration before each test
  before do
    Geminize::Configuration.instance.reset!
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_an_instance_of(Geminize::Configuration)
    end

    it "returns the singleton instance" do
      expect(described_class.configuration).to be(Geminize::Configuration.instance)
    end
  end

  describe ".configure" do
    it "yields the configuration object to the block" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(an_instance_of(Geminize::Configuration))
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.api_version = "test-version"
        config.default_model = "test-model"
      end

      expect(described_class.configuration.api_key).to eq("test-key")
      expect(described_class.configuration.api_version).to eq("test-version")
      expect(described_class.configuration.default_model).to eq("test-model")
    end

    it "returns the configuration object" do
      result = described_class.configure do |config|
        config.api_key = "test-key"
      end
      expect(result).to be(described_class.configuration)
    end
  end

  describe ".reset_configuration!" do
    it "resets the configuration to defaults" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.api_version = "test-version"
      end

      described_class.reset_configuration!

      expect(described_class.configuration.api_key).to eq(ENV["GEMINI_API_KEY"])
      expect(described_class.configuration.api_version).to eq(Geminize::Configuration::DEFAULT_API_VERSION)
    end
  end

  describe ".validate_configuration!" do
    it "delegates to the configuration object" do
      expect(described_class.configuration).to receive(:validate!)
      described_class.validate_configuration!
    end

    it "raises ConfigurationError when configuration is invalid" do
      allow(described_class.configuration).to receive(:validate!).and_raise(Geminize::ConfigurationError, "Test error")
      expect { described_class.validate_configuration! }.to raise_error(Geminize::ConfigurationError, "Test error")
    end
  end

  describe ".generate_text", :vcr do
    let(:prompt) { "Tell me a story about a dragon" }
    let(:model_name) { "gemini-2.0-flash" }

    before do
      # Configure with real API key from env
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"]
        config.default_model = model_name
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "successfully generates text with default model", vcr: {cassette_name: "generate_text_default_model"} do
      response = Geminize.generate_text(prompt)

      # Test that we get a valid response object with content
      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates text with specified model", vcr: {cassette_name: "generate_text_specified_model"} do
      response = Geminize.generate_text(prompt, model_name)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates text with generation parameters", vcr: {cassette_name: "generate_text_with_parameters"} do
      params = {temperature: 0.8, max_tokens: 200}

      response = Geminize.generate_text(prompt, model_name, params)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates text without retries", vcr: {cassette_name: "generate_text_without_retries"} do
      response = Geminize.generate_text(prompt, nil, with_retries: false)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates text with custom retry parameters", vcr: {cassette_name: "generate_text_custom_retries"} do
      response = Geminize.generate_text(prompt, nil, max_retries: 5, retry_delay: 2.0)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates text with client options", vcr: {cassette_name: "generate_text_client_options"} do
      client_options = {timeout: 30}

      response = Geminize.generate_text(prompt, nil, client_options: client_options)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end
  end

  describe ".generate_multimodal", :vcr do
    let(:prompt) { "Describe this image" }
    let(:model_name) { "gemini-2.0-flash" }

    # We'll use a stub to avoid actually making API calls for these tests
    let(:mock_client) { instance_double(Geminize::Client) }
    let(:mock_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "This is a description of the image. It appears to be a cake with chocolate frosting."
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "modelVersion" => "gemini-2.0-flash",
        "usageMetadata" => {
          "promptTokenCount" => 25,
          "candidatesTokenCount" => 16,
          "totalTokenCount" => 41
        }
      }
    end

    before do
      # Configure with API key
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"]
        config.default_model = model_name
      end

      # Setup the mock client
      allow(Geminize::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:post).and_return(mock_response)
    end

    after do
      Geminize.reset_configuration!
    end

    it "successfully generates multimodal content", vcr: {cassette_name: "generate_multimodal"} do
      image_data = {
        source_type: "url",
        data: "https://storage.googleapis.com/generativeai-downloads/images/cake.jpg"
      }

      response = Geminize.generate_multimodal(prompt, [image_data])

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates multimodal content with specified model", vcr: {cassette_name: "generate_multimodal_specified_model"} do
      image_data = {
        source_type: "url",
        data: "https://storage.googleapis.com/generativeai-downloads/images/cake.jpg"
      }

      response = Geminize.generate_multimodal(prompt, [image_data], model_name)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end
  end
end
