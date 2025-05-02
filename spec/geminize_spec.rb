# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive information
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }

  # Create custom URI matcher that ignores API key
  uri_without_api_key = lambda do |request_1, request_2|
    uri1 = URI(request_1.uri).to_s.gsub(/[?&]key=[^&]+(&|$)/, '\1')
    uri2 = URI(request_2.uri).to_s.gsub(/[?&]key=[^&]+(&|$)/, '\1')
    uri1 == uri2
  end

  # Set default record mode - record once and replay afterwards
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, uri_without_api_key, :body]
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
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
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

  describe ".generate_text_multimodal", :vcr do
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
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.default_model = model_name
      end

      # Setup the mock client
      allow(Geminize::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:post).and_return(mock_response)
    end

    after do
      Geminize.reset_configuration!
    end

    it "successfully generates multimodal content", vcr: {cassette_name: "generate_text_multimodal"} do
      image_data = {
        source_type: "url",
        data: "https://storage.googleapis.com/generativeai-downloads/images/cake.jpg"
      }

      response = Geminize.generate_text_multimodal(prompt, [image_data])

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to be_a(String)
      expect(response.text).not_to be_empty
    end

    it "successfully generates multimodal content with specified model", vcr: {cassette_name: "generate_text_multimodal_specified_model"} do
      image_data = {
        source_type: "url",
        data: "https://storage.googleapis.com/generativeai-downloads/images/cake.jpg"
      }

      response = Geminize.generate_text_multimodal(prompt, [image_data], model_name)

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
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
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

  describe ".generate_embedding", :vcr do
    let(:text) { "What is the meaning of life?" }
    let(:model_name) { "gemini-embedding-exp-03-07" }

    before do
      # Configure with real API key from env
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.default_embedding_model = model_name
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "successfully generates embeddings with default model", vcr: {cassette_name: "generate_embedding_default_model"} do
      response = Geminize.generate_embedding(text)
      # Test that we get a valid response object with embeddings
      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "successfully generates embeddings with specified model", vcr: {cassette_name: "generate_embedding_specified_model"} do
      response = Geminize.generate_embedding(text, model_name)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "successfully generates embeddings with task_type parameter", vcr: {cassette_name: "generate_embedding_with_task_type"} do
      params = {task_type: Geminize::Models::EmbeddingRequest::SEMANTIC_SIMILARITY}

      response = Geminize.generate_embedding(text, model_name, params)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "successfully generates embeddings for multiple texts", vcr: {cassette_name: "generate_embedding_multiple_texts"} do
      texts = ["What is the meaning of life?", "How does gravity work?", "What makes the sky blue?"]

      response = Geminize.generate_embedding(texts, model_name)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings.length).to eq(texts.length)
    end

    it "successfully handles batching for large arrays of texts", vcr: {cassette_name: "generate_embedding_batching"} do
      # Create an array of 5 texts (small enough for testing but forces batching with batch_size=2)
      texts = Array.new(5) { |i| "This is test text #{i}" }

      response = Geminize.generate_embedding(texts, model_name, batch_size: 2)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings.length).to eq(texts.length)
    end

    it "successfully generates embeddings without retries", vcr: {cassette_name: "generate_embedding_without_retries"} do
      response = Geminize.generate_embedding(text, nil, with_retries: false)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "successfully generates embeddings with custom retry parameters", vcr: {cassette_name: "generate_embedding_custom_retries"} do
      response = Geminize.generate_embedding(text, nil, max_retries: 5, retry_delay: 2.0)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "successfully generates embeddings with client options", vcr: {cassette_name: "generate_embedding_client_options"} do
      client_options = {timeout: 30}

      response = Geminize.generate_embedding(text, nil, client_options: client_options)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles SEMANTIC_SIMILARITY task type", vcr: {cassette_name: "generate_embedding_with_task_type_semantic_similarity"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::SEMANTIC_SIMILARITY)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles CLASSIFICATION task type", vcr: {cassette_name: "generate_embedding_with_task_type_classification"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::CLASSIFICATION)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles CLUSTERING task type", vcr: {cassette_name: "generate_embedding_with_task_type_clustering"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::CLUSTERING)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles RETRIEVAL_DOCUMENT task type", vcr: {cassette_name: "generate_embedding_with_task_type_retrieval_document"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::RETRIEVAL_DOCUMENT)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles QUESTION_ANSWERING task type", vcr: {cassette_name: "generate_embedding_with_task_type_question_answering"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::QUESTION_ANSWERING)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles FACT_VERIFICATION task type", vcr: {cassette_name: "generate_embedding_with_task_type_fact_verification"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::FACT_VERIFICATION)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles CODE_RETRIEVAL_QUERY task type", vcr: {cassette_name: "generate_embedding_with_task_type_code_retrieval_query"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::CODE_RETRIEVAL_QUERY)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "correctly handles TASK_TYPE_UNSPECIFIED task type", vcr: {cassette_name: "generate_embedding_with_task_type_unspecified"} do
      response = Geminize.generate_embedding(text, model_name, task_type: Geminize::Models::EmbeddingRequest::TASK_TYPE_UNSPECIFIED)

      expect(response).to be_a(Geminize::Models::EmbeddingResponse)
      expect(response.embeddings).to be_an(Array)
      expect(response.embeddings).not_to be_empty
    end

    it "properly handles rate limit errors with retries" do
      mock_embeddings = instance_double(Geminize::Embeddings)
      mock_response = instance_double(Geminize::Models::EmbeddingResponse)
      mock_embeddings_data = [0.1, 0.2, 0.3, 0.4, 0.5]

      # Set up to throw rate limit error on first call, then succeed
      call_count = 0
      allow(Geminize::Embeddings).to receive(:new).and_return(mock_embeddings)
      allow(mock_embeddings).to receive(:generate_embedding) do
        call_count += 1
        if call_count == 1
          raise Geminize::RateLimitError, "Rate limit exceeded"
        else
          mock_response
        end
      end

      # Mock the response for successful call
      allow(mock_response).to receive(:embeddings).and_return(mock_embeddings_data)
      allow(mock_response).to receive(:is_a?).with(Geminize::Models::EmbeddingResponse).and_return(true)

      # Reduce sleep time for faster test
      allow_any_instance_of(Object).to receive(:sleep)

      # Call with retry parameters
      response = Geminize.generate_embedding(text, model_name, max_retries: 3, retry_delay: 0.1)

      # Verify we got the response after retry
      expect(response).to be(mock_response)
      expect(call_count).to eq(2)
    end

    it "raises error after max retries exceeded" do
      mock_embeddings = instance_double(Geminize::Embeddings)

      # Set up to always throw rate limit error
      allow(Geminize::Embeddings).to receive(:new).and_return(mock_embeddings)
      allow(mock_embeddings).to receive(:generate_embedding).and_raise(Geminize::RateLimitError, "Rate limit exceeded")

      # Reduce sleep time for faster test
      allow_any_instance_of(Object).to receive(:sleep)

      # Call with retry parameters - should fail after max retries
      expect {
        Geminize.generate_embedding(text, model_name, max_retries: 2, retry_delay: 0.1)
      }.to raise_error(Geminize::RateLimitError, "Rate limit exceeded")
    end

    it "wraps other exceptions in GeminizeError", vcr: {cassette_name: "generate_embedding_invalid_model"} do
      expect {
        Geminize.generate_embedding(text, "invalid-model-name")
      }.to raise_error(Geminize::GeminizeError)
    end
  end

  describe ".chat", :vcr do
    let(:message) { "Hello, how are you today?" }
    let(:model_name) { "gemini-2.0-flash" }

    before do
      # Configure with real API key from env
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.default_model = model_name
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "creates a new chat and sends a message with default model", vcr: {cassette_name: "chat_new_default_model", record: :once} do
      result = Geminize.chat(message)

      # Verify result structure
      expect(result).to be_a(Hash)
      expect(result[:response]).to be_a(Geminize::Models::ChatResponse)
      expect(result[:chat]).to be_a(Geminize::Chat)

      # Verify response content
      expect(result[:response].text).to be_a(String)
      expect(result[:response].text).not_to be_empty

      # Verify chat state
      expect(result[:chat].conversation.messages.length).to be >= 2 # At least user message and model response
    end

    it "sends a message with an existing chat", vcr: {cassette_name: "chat_existing_chat", record: :once} do
      # First create a chat
      chat = Geminize.create_chat("Test Conversation")

      # Send first message to establish context
      first_result = Geminize.chat("My name is Ruby", chat)

      # Send second message using the same chat
      second_result = Geminize.chat("What's my name?", first_result[:chat])

      # Verify the second response
      expect(second_result[:response].text).to include("Ruby")

      # Verify it's the same chat instance
      expect(second_result[:chat]).to be(first_result[:chat])

      # Verify chat history contains all messages
      expect(second_result[:chat].conversation.messages.length).to be >= 4 # At least 2 user messages and 2 model responses
    end

    it "sends a message with specified model", vcr: {cassette_name: "chat_specified_model", record: :once} do
      specified_model = "gemini-2.0-flash" # Using same model as default but explicitly specified

      result = Geminize.chat(message, nil, specified_model)

      # Verify result structure and content
      expect(result[:response]).to be_a(Geminize::Models::ChatResponse)
      expect(result[:response].text).to be_a(String)
      expect(result[:response].text).not_to be_empty

      # We can't directly test the model name here since Chat doesn't expose it
      # Instead, verify that we get a valid response when using the specified model
      expect(result[:chat]).to be_a(Geminize::Chat)
    end

    it "sends a message with generation parameters", vcr: {cassette_name: "chat_with_parameters", record: :once} do
      params = {temperature: 0.3, max_tokens: 100}

      result = Geminize.chat(message, nil, nil, params)

      # Verify result structure and content
      expect(result[:response]).to be_a(Geminize::Models::ChatResponse)
      expect(result[:response].text).to be_a(String)
      expect(result[:response].text).not_to be_empty
    end

    it "sends a message with client options", vcr: {cassette_name: "chat_client_options", record: :once} do
      client_options = {timeout: 30}

      result = Geminize.chat(message, nil, nil, client_options: client_options)

      # Verify result structure and content
      expect(result[:response]).to be_a(Geminize::Models::ChatResponse)
      expect(result[:response].text).to be_a(String)
      expect(result[:response].text).not_to be_empty
    end
  end

  describe ".list_models", :vcr do
    before do
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.api_version = "v1"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "retrieves a list of models", vcr: {cassette_name: "list_models"} do
      model_list = Geminize.list_models

      expect(model_list).to be_a(Geminize::Models::ModelList)
      expect(model_list.size).to be > 0

      # Verify the model objects have the expected structure
      first_model = model_list.first
      expect(first_model).to be_a(Geminize::Models::Model)
      expect(first_model.name).to be_a(String)
      expect(first_model.name).to include("models/")
    end

    it "handles pagination parameters", vcr: {cassette_name: "list_models_with_pagination"} do
      # First get a page of results
      first_page = Geminize.list_models(page_size: 2)

      # If there's a next page, get it
      if first_page.has_more_pages?
        second_page = Geminize.list_models(page_size: 2, page_token: first_page.next_page_token)
        expect(second_page).to be_a(Geminize::Models::ModelList)
        expect(second_page.size).to be > 0

        # The models on second page should be different from the first page
        expect(second_page.first.name).not_to eq(first_page.first.name)
      else
        # Skip this test if we don't have enough models to paginate
        skip "Not enough models to test pagination"
      end
    end
  end

  describe ".list_all_models", :vcr do
    before do
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.api_version = "v1"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "retrieves all models across pages", vcr: {cassette_name: "list_all_models"} do
      all_models = Geminize.list_all_models

      expect(all_models).to be_a(Geminize::Models::ModelList)
      expect(all_models.size).to be > 0

      # We can't know the exact number, but we should have several models
      expect(all_models.size).to be >= 5
    end
  end

  describe ".get_model", :vcr do
    let(:model_name) { "gemini-1.5-pro" }

    before do
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.api_version = "v1"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "retrieves a specific model by name", vcr: {cassette_name: "get_model"} do
      model = Geminize.get_model(model_name)

      expect(model).to be_a(Geminize::Models::Model)
      expect(model.name).to include(model_name)
      expect(model.id).to eq(model_name)

      # Check that the model has all expected attributes
      expect(model.display_name).to be_a(String)
      expect(model.description).to be_a(String)
      expect(model.supported_generation_methods).to be_an(Array)
    end

    it "handles models with full path names", vcr: {cassette_name: "get_model_full_path"} do
      full_name = "models/#{model_name}"
      model = Geminize.get_model(full_name)

      expect(model).to be_a(Geminize::Models::Model)
      expect(model.id).to eq(model_name)
    end

    it "raises an error for non-existent models", vcr: {cassette_name: "get_non_existent_model"} do
      expect {
        Geminize.get_model("non-existent-model-123456")
      }.to raise_error(Geminize::ResourceNotFoundError)
    end
  end

  describe "model filtering methods", :vcr do
    before do
      Geminize.configure do |config|
        config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key"
        config.api_version = "v1"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    it "filters content generation models", vcr: {cassette_name: "get_content_generation_models"} do
      models = Geminize.get_content_generation_models

      expect(models).to be_a(Geminize::Models::ModelList)
      expect(models.size).to be > 0

      # All returned models should support content generation
      models.each do |model|
        expect(model.supports_content_generation?).to be true
      end
    end

    it "filters embedding models", vcr: {cassette_name: "get_embedding_models"} do
      models = Geminize.get_embedding_models

      expect(models).to be_a(Geminize::Models::ModelList)

      # All returned models should support embeddings
      models.each do |model|
        expect(model.supports_embedding?).to be true
      end
    end

    it "filters chat models", vcr: {cassette_name: "get_chat_models"} do
      models = Geminize.get_chat_models

      expect(models).to be_a(Geminize::Models::ModelList)

      # All returned models should support chat
      models.each do |model|
        expect(model.supports_message_generation?).to be true
      end
    end

    it "filters streaming models", vcr: {cassette_name: "get_streaming_models"} do
      models = Geminize.get_streaming_models

      expect(models).to be_a(Geminize::Models::ModelList)

      # All returned models should support streaming
      models.each do |model|
        expect(model.supports_streaming?).to be true
      end
    end

    it "gets models by a specific generation method", vcr: {cassette_name: "get_models_by_method"} do
      models = Geminize.get_models_by_method("generateContent")

      expect(models).to be_a(Geminize::Models::ModelList)
      expect(models.size).to be > 0

      # All returned models should support the specified method
      models.each do |model|
        expect(model.supports_method?("generateContent")).to be true
      end
    end
  end
end
