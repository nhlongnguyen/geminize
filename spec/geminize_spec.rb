# frozen_string_literal: true

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

  describe ".generate_text" do
    let(:mock_generator) { instance_double(Geminize::TextGeneration) }
    let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }
    let(:prompt) { "Tell me a story about a dragon" }
    let(:model_name) { "gemini-1.5-pro-latest" }

    before do
      allow(Geminize::TextGeneration).to receive(:new).and_return(mock_generator)
      allow(mock_generator).to receive(:generate).and_return(mock_response)
      allow(mock_generator).to receive(:generate_with_retries).and_return(mock_response)

      # Configure with valid API key
      Geminize.configure do |config|
        config.api_key = "test-api-key"
        config.default_model = "gemini-1.5-flash-latest"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "validates the configuration" do
      expect(Geminize).to receive(:validate_configuration!)
      Geminize.generate_text(prompt)
    end

    it "uses the default model if none provided" do
      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        "gemini-1.5-flash-latest",
        {}
      ).and_call_original

      Geminize.generate_text(prompt)
    end

    it "uses the provided model if specified" do
      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        model_name,
        {}
      ).and_call_original

      Geminize.generate_text(prompt, model_name)
    end

    it "passes generation parameters to the content request" do
      params = {temperature: 0.8, max_tokens: 200}

      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        model_name,
        params
      ).and_call_original

      Geminize.generate_text(prompt, model_name, params)
    end

    it "uses generate_with_retries by default" do
      content_request = instance_double(Geminize::Models::ContentRequest)
      allow(Geminize::Models::ContentRequest).to receive(:new).and_return(content_request)

      expect(mock_generator).to receive(:generate_with_retries).with(content_request, 3, 1.0)
      Geminize.generate_text(prompt)
    end

    it "disables retries when with_retries is false" do
      content_request = instance_double(Geminize::Models::ContentRequest)
      allow(Geminize::Models::ContentRequest).to receive(:new).and_return(content_request)

      expect(mock_generator).to receive(:generate).with(content_request)
      Geminize.generate_text(prompt, nil, with_retries: false)
    end

    it "uses custom retry parameters when provided" do
      content_request = instance_double(Geminize::Models::ContentRequest)
      allow(Geminize::Models::ContentRequest).to receive(:new).and_return(content_request)

      expect(mock_generator).to receive(:generate_with_retries).with(content_request, 5, 2.0)
      Geminize.generate_text(prompt, nil, max_retries: 5, retry_delay: 2.0)
    end

    it "passes client options to the TextGeneration constructor" do
      client_options = {timeout: 30}

      expect(Geminize::TextGeneration).to receive(:new).with(nil, client_options)
      Geminize.generate_text(prompt, nil, client_options: client_options)
    end

    it "returns the response from the generator" do
      result = Geminize.generate_text(prompt)
      expect(result).to eq(mock_response)
    end
  end

  describe ".generate_multimodal" do
    let(:mock_generator) { instance_double(Geminize::TextGeneration) }
    let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }
    let(:prompt) { "Describe this image" }
    let(:model_name) { "gemini-1.5-pro-latest" }
    let(:image_file_path) { "/path/to/image.jpg" }
    let(:image_url) { "https://example.com/image.jpg" }
    let(:images) { [{source_type: "file", data: image_file_path}] }
    let(:content_request) { instance_double(Geminize::Models::ContentRequest) }

    before do
      allow(Geminize::TextGeneration).to receive(:new).and_return(mock_generator)
      allow(Geminize::Models::ContentRequest).to receive(:new).and_return(content_request)
      allow(content_request).to receive(:add_image_from_file).and_return(content_request)
      allow(content_request).to receive(:add_image_from_url).and_return(content_request)
      allow(content_request).to receive(:add_image_from_bytes).and_return(content_request)
      allow(mock_generator).to receive(:generate).and_return(mock_response)
      allow(mock_generator).to receive(:generate_with_retries).and_return(mock_response)

      # Configure with valid API key
      Geminize.configure do |config|
        config.api_key = "test-api-key"
        config.default_model = "gemini-1.5-flash-latest"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "validates the configuration" do
      expect(Geminize).to receive(:validate_configuration!)
      Geminize.generate_multimodal(prompt, images)
    end

    it "uses the default model if none provided" do
      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        "gemini-1.5-flash-latest",
        {}
      )

      Geminize.generate_multimodal(prompt, images)
    end

    it "uses the provided model if specified" do
      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        model_name,
        {}
      )

      Geminize.generate_multimodal(prompt, images, model_name)
    end

    it "passes generation parameters to the content request" do
      params = {temperature: 0.8, max_tokens: 200}

      expect(Geminize::Models::ContentRequest).to receive(:new).with(
        prompt,
        model_name,
        params
      )

      Geminize.generate_multimodal(prompt, images, model_name, params)
    end

    it "adds each image to the content request" do
      expect(content_request).to receive(:add_image_from_file).with(image_file_path)
      Geminize.generate_multimodal(prompt, images)
    end

    it "adds multiple images of different types" do
      multiple_images = [
        {source_type: "file", data: image_file_path},
        {source_type: "url", data: image_url}
      ]

      expect(content_request).to receive(:add_image_from_file).with(image_file_path)
      expect(content_request).to receive(:add_image_from_url).with(image_url)

      Geminize.generate_multimodal(prompt, multiple_images)
    end

    it "raises an error for invalid image source types" do
      invalid_images = [{source_type: "invalid", data: image_file_path}]

      expect {
        Geminize.generate_multimodal(prompt, invalid_images)
      }.to raise_error(Geminize::ValidationError, /Invalid image source type/)
    end

    it "uses generate_with_retries by default" do
      expect(mock_generator).to receive(:generate_with_retries).with(content_request, 3, 1.0)
      Geminize.generate_multimodal(prompt, images)
    end

    it "disables retries when with_retries is false" do
      expect(mock_generator).to receive(:generate).with(content_request)
      Geminize.generate_multimodal(prompt, images, nil, with_retries: false)
    end

    it "uses custom retry parameters when provided" do
      expect(mock_generator).to receive(:generate_with_retries).with(content_request, 5, 2.0)
      Geminize.generate_multimodal(prompt, images, nil, max_retries: 5, retry_delay: 2.0)
    end

    it "passes client options to the TextGeneration constructor" do
      client_options = {timeout: 30}

      expect(Geminize::TextGeneration).to receive(:new).with(nil, client_options)
      Geminize.generate_multimodal(prompt, images, nil, client_options: client_options)
    end

    it "returns the response from the generator" do
      result = Geminize.generate_multimodal(prompt, images)
      expect(result).to eq(mock_response)
    end
  end
end
