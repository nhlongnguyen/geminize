# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentResponse do
  let(:generated_text) { "Once upon a time, there was a dragon." }
  let(:raw_response) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => generated_text
              }
            ],
            "role" => "model"
          },
          "finishReason" => "STOP",
          "index" => 0,
          "safetyRatings" => [
            {
              "category" => "HARM_CATEGORY_DANGEROUS_CONTENT",
              "probability" => "NEGLIGIBLE"
            }
          ]
        }
      ],
      "promptFeedback" => {
        "safetyRatings" => [
          {
            "category" => "HARM_CATEGORY_DANGEROUS_CONTENT",
            "probability" => "NEGLIGIBLE"
          }
        ]
      },
      "usageMetadata" => {
        "promptTokenCount" => 20,
        "candidatesTokenCount" => 15,
        "totalTokenCount" => 35
      }
    }
  end

  let(:empty_response) do
    {
      "candidates" => [],
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

  describe "#initialize" do
    it "stores the raw response" do
      response = described_class.new(raw_response)
      expect(response.raw_response).to eq(raw_response)
    end

    it "parses finish reason" do
      response = described_class.new(raw_response)
      expect(response.finish_reason).to eq("STOP")
    end

    it "parses usage metadata" do
      response = described_class.new(raw_response)
      expect(response.usage).to eq(raw_response["usageMetadata"])
    end
  end

  describe "#text" do
    it "extracts text from candidates" do
      response = described_class.new(raw_response)
      expect(response.text).to eq(generated_text)
    end

    it "handles missing text" do
      response = described_class.new(empty_response)
      expect(response.text).to be_nil
    end

    context "with multiple text parts" do
      let(:raw_response_with_multiple_parts) do
        {
          "candidates" => [
            {
              "content" => {
                "parts" => [
                  {"text" => "Part 1"},
                  {"text" => "Part 2"}
                ],
                "role" => "model"
              },
              "finishReason" => "STOP"
            }
          ]
        }
      end

      it "joins multiple text parts" do
        response = described_class.new(raw_response_with_multiple_parts)
        expect(response.text).to eq("Part 1 Part 2")
      end
    end
  end

  describe "#has_text?" do
    it "returns true when text is present" do
      response = described_class.new(raw_response)
      expect(response.has_text?).to be true
    end

    it "returns false when text is missing" do
      response = described_class.new(empty_response)
      expect(response.has_text?).to be false
    end
  end

  describe "#total_tokens" do
    it "returns sum of prompt and completion tokens" do
      response = described_class.new(raw_response)
      expect(response.total_tokens).to eq(35)
    end

    it "returns nil when usage metadata is missing" do
      response = described_class.new(empty_response)
      expect(response.total_tokens).to be_nil
    end
  end

  describe "#prompt_tokens" do
    it "returns prompt token count" do
      response = described_class.new(raw_response)
      expect(response.prompt_tokens).to eq(20)
    end

    it "returns nil when usage metadata is missing" do
      response = described_class.new(empty_response)
      expect(response.prompt_tokens).to be_nil
    end
  end

  describe "#completion_tokens" do
    it "returns completion token count" do
      response = described_class.new(raw_response)
      expect(response.completion_tokens).to eq(15)
    end

    it "returns nil when usage metadata is missing" do
      response = described_class.new(empty_response)
      expect(response.completion_tokens).to be_nil
    end
  end

  describe ".from_hash" do
    it "creates a ContentResponse from a hash" do
      response = described_class.from_hash(raw_response)
      expect(response).to be_a(described_class)
      expect(response.raw_response).to eq(raw_response)
    end
  end
end
