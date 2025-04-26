# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::TextGeneration do
  let(:client) { instance_double(Geminize::Client) }
  let(:prompt) { "Tell me a story about a dragon" }
  let(:model_name) { "gemini-2.0-flash" }
  let(:default_model) { "gemini-2.0-flash" }
  let(:generation_endpoint) { "models/#{model_name}:generateContent" }

  let(:mock_response) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "Once upon a time, there was a dragon."
              }
            ],
            "role" => "model"
          },
          "finishReason" => "STOP",
          "index" => 0
        }
      ],
      "promptFeedback" => {
        "safetyRatings" => [
          {
            "category" => "HARM_CATEGORY_DANGEROUS_CONTENT",
            "probability" => "NEGLIGIBLE"
          }
        ]
      }
    }
  end

  before do
    allow(Geminize.configuration).to receive(:default_model).and_return(default_model)
  end

  describe "#initialize" do
    it "creates a new client if none is provided" do
      expect(Geminize::Client).to receive(:new).and_return(client)
      text_generation = described_class.new
      expect(text_generation.client).to eq(client)
    end

    it "uses the provided client" do
      text_generation = described_class.new(client)
      expect(text_generation.client).to eq(client)
    end
  end

  describe "#generate" do
    let(:text_generation) { described_class.new(client) }
    let(:content_request) do
      Geminize::Models::ContentRequest.new(
        prompt,
        model_name,
        temperature: 0.7,
        max_tokens: 100
      )
    end

    let(:expected_request) do
      Geminize::RequestBuilder.build_text_generation_request(content_request)
    end

    it "sends a correctly formatted request to the API" do
      expect(Geminize::RequestBuilder).to receive(:build_text_generation_endpoint)
        .with(model_name)
        .and_return(generation_endpoint)

      expect(Geminize::RequestBuilder).to receive(:build_text_generation_request)
        .with(content_request)
        .and_return(expected_request)

      expect(client).to receive(:post)
        .with(generation_endpoint, expected_request)
        .and_return(mock_response)

      response = text_generation.generate(content_request)

      expect(response).to be_a(Geminize::Models::ContentResponse)
      expect(response.text).to eq("Once upon a time, there was a dragon.")
    end
  end

  describe "#generate_text" do
    let(:text_generation) { described_class.new(client) }

    before do
      allow(client).to receive(:post).and_return(mock_response)
    end

    it "creates a ContentRequest and calls generate" do
      expect(Geminize::Models::ContentRequest).to receive(:new)
        .with(prompt, default_model, {temperature: 0.7})
        .and_call_original

      response = text_generation.generate_text(prompt, nil, temperature: 0.7)

      expect(response).to be_a(Geminize::Models::ContentResponse)
    end

    it "uses the provided model name" do
      custom_model = "gemini-1.5-flash"

      expect(Geminize::Models::ContentRequest).to receive(:new)
        .with(prompt, custom_model, {})
        .and_call_original

      text_generation.generate_text(prompt, custom_model)
    end
  end

  describe "#generate_multimodal" do
    let(:text_generation) { described_class.new(client) }
    let(:prompt) { "Describe this image" }
    let(:image_file_path) { "/path/to/image.jpg" }
    let(:image_url) { "https://example.com/image.jpg" }
    let(:image_bytes) { "fake-image-bytes" }
    let(:mime_type) { "image/jpeg" }

    let(:content_request) do
      instance_double(Geminize::Models::ContentRequest,
        add_image_from_file: nil,
        add_image_from_url: nil,
        add_image_from_bytes: nil)
    end

    before do
      allow(Geminize::Models::ContentRequest).to receive(:new).and_return(content_request)
      allow(text_generation).to receive(:generate).and_return(Geminize::Models::ContentResponse.new(mock_response))
    end

    context "with image file" do
      it "adds image from file path to the request" do
        images = [{source_type: "file", data: image_file_path}]

        expect(content_request).to receive(:add_image_from_file).with(image_file_path)

        response = text_generation.generate_multimodal(prompt, images, model_name)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end
    end

    context "with image URL" do
      it "adds image from URL to the request" do
        images = [{source_type: "url", data: image_url}]

        expect(content_request).to receive(:add_image_from_url).with(image_url)

        response = text_generation.generate_multimodal(prompt, images, model_name)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end
    end

    context "with raw image bytes" do
      it "adds image from bytes to the request" do
        images = [{source_type: "bytes", data: image_bytes, mime_type: mime_type}]

        expect(content_request).to receive(:add_image_from_bytes).with(image_bytes, mime_type)

        response = text_generation.generate_multimodal(prompt, images, model_name)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end
    end

    context "with multiple images" do
      it "adds all images to the request" do
        images = [
          {source_type: "file", data: image_file_path},
          {source_type: "url", data: image_url}
        ]

        expect(content_request).to receive(:add_image_from_file).with(image_file_path)
        expect(content_request).to receive(:add_image_from_url).with(image_url)

        response = text_generation.generate_multimodal(prompt, images, model_name)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end
    end

    context "with invalid source type" do
      it "raises a validation error" do
        images = [{source_type: "invalid", data: image_file_path}]

        expect {
          text_generation.generate_multimodal(prompt, images, model_name)
        }.to raise_error(Geminize::ValidationError, /Invalid image source type/)
      end
    end
  end

  describe "#generate_with_retries" do
    let(:text_generation) { described_class.new(client) }
    let(:content_request) do
      Geminize::Models::ContentRequest.new(prompt, model_name)
    end

    context "when request succeeds" do
      it "returns the response without retrying" do
        expect(text_generation).to receive(:generate)
          .with(content_request)
          .once
          .and_return(Geminize::Models::ContentResponse.new(mock_response))

        expect(text_generation).not_to receive(:sleep)

        response = text_generation.generate_with_retries(content_request, 3, 0)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end
    end

    context "when request fails with retryable error" do
      it "retries the request" do
        expect(text_generation).to receive(:generate)
          .with(content_request)
          .ordered
          .and_raise(Geminize::RateLimitError.new)

        expect(text_generation).to receive(:sleep).with(1.0).ordered

        expect(text_generation).to receive(:generate)
          .with(content_request)
          .ordered
          .and_return(Geminize::Models::ContentResponse.new(mock_response))

        response = text_generation.generate_with_retries(content_request, 3, 1.0)
        expect(response).to be_a(Geminize::Models::ContentResponse)
      end

      it "gives up after max retries" do
        error = Geminize::ServerError.new

        expect(text_generation).to receive(:generate)
          .with(content_request)
          .exactly(4).times
          .and_raise(error)

        expect(text_generation).to receive(:sleep).exactly(3).times

        expect { text_generation.generate_with_retries(content_request, 3, 0) }
          .to raise_error(Geminize::ServerError)
      end
    end
  end
end
