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

  describe ".generate_text_stream", :vcr do
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

    it "requires a block to be given" do
      expect {
        Geminize.generate_text_stream(prompt)
      }.to raise_error(ArgumentError, "A block is required for streaming")
    end

    it "properly streams text with default options", vcr: {cassette_name: "generate_text_stream_default"} do
      chunks_received = 0
      accumulated_text = ""

      Geminize.generate_text_stream(prompt) do |chunk|
        chunks_received += 1

        # Only append to accumulated_text if it's not the final chunk with metrics
        unless chunk.is_a?(Hash) && chunk[:usage]
          accumulated_text += chunk
        end
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1

      # Verify we received substantial content
      expect(accumulated_text).not_to be_empty
      expect(accumulated_text.length).to be > 50
    end

    it "properly streams text with delta mode", vcr: {cassette_name: "generate_text_stream_delta"} do
      chunks_received = 0
      accumulated_text = ""

      Geminize.generate_text_stream(prompt, nil, stream_mode: :delta) do |chunk|
        chunks_received += 1

        # Only append to accumulated_text if it's not the final chunk with metrics
        unless chunk.is_a?(Hash) && chunk[:usage]
          accumulated_text += chunk
        end
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1

      # Verify we received substantial content
      expect(accumulated_text).not_to be_empty
      expect(accumulated_text.length).to be > 50
    end

    it "properly streams text with raw mode", vcr: {cassette_name: "generate_text_stream_raw"} do
      chunks_received = 0

      Geminize.generate_text_stream(prompt, nil, stream_mode: :raw) do |chunk|
        chunks_received += 1

        # Verify each chunk is a hash with the expected structure
        expect(chunk).to be_a(Hash)
        expect(chunk["candidates"]).to be_an(Array)
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1
    end

    it "properly streams text with a specific model", vcr: {cassette_name: "generate_text_stream_specific_model"} do
      custom_model = "gemini-1.5-pro"
      chunks_received = 0
      accumulated_text = ""

      Geminize.generate_text_stream(prompt, custom_model) do |chunk|
        chunks_received += 1

        # Only append to accumulated_text if it's not the final chunk with metrics
        unless chunk.is_a?(Hash) && chunk[:usage]
          accumulated_text += chunk
        end
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1

      # Verify we received substantial content
      expect(accumulated_text).not_to be_empty
      expect(accumulated_text.length).to be > 50
    end

    it "properly streams text with generation parameters", vcr: {cassette_name: "generate_text_stream_parameters"} do
      params = {temperature: 0.8, max_tokens: 100}
      chunks_received = 0
      accumulated_text = ""

      Geminize.generate_text_stream(prompt, nil, params) do |chunk|
        chunks_received += 1

        # Only append to accumulated_text if it's not the final chunk with metrics
        unless chunk.is_a?(Hash) && chunk[:usage]
          accumulated_text += chunk
        end
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1

      # Verify we received substantial content
      expect(accumulated_text).not_to be_empty
      expect(accumulated_text.length).to be > 50
    end

    it "properly streams text with client options", vcr: {cassette_name: "generate_text_stream_client_options"} do
      client_options = {timeout: 30}
      chunks_received = 0
      accumulated_text = ""

      Geminize.generate_text_stream(prompt, nil, client_options: client_options) do |chunk|
        chunks_received += 1

        # Only append to accumulated_text if it's not the final chunk with metrics
        unless chunk.is_a?(Hash) && chunk[:usage]
          accumulated_text += chunk
        end
      end

      # Verify we received multiple chunks
      expect(chunks_received).to be > 1

      # Verify we received substantial content
      expect(accumulated_text).not_to be_empty
      expect(accumulated_text.length).to be > 50
    end

    it "supports cancellation during streaming" do
      chunks_received = 0

      generator = instance_double(Geminize::TextGeneration)
      allow(Geminize::TextGeneration).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate_text_stream) do |&block|
        # Simulate the first chunk
        block.call("Once upon a time")
      end
      allow(generator).to receive(:cancel_streaming).and_return(true)

      # Set up to call cancel_streaming after receiving the first chunk
      Geminize.generate_text_stream(prompt) do |_|
        chunks_received += 1
        Geminize.cancel_streaming if chunks_received >= 1
      end

      # Should have received one chunk
      expect(chunks_received).to eq(1)
    end

    it "wraps non-GeminizeError exceptions in a GeminizeError", vcr: {cassette_name: "generate_text_stream_error"} do
      # We'll use a malformed model name to provoke an error
      expect {
        Geminize.generate_text_stream(prompt, "invalid-model") { |_| }
      }.to raise_error(Geminize::GeminizeError)
    end
  end
end
