# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::StreamResponse do
  let(:regular_chunk) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "Hello, "
              }
            ],
            "role" => "model"
          },
          "index" => 0
        }
      ]
    }
  end

  let(:final_chunk) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "world!"
              }
            ],
            "role" => "model"
          },
          "finishReason" => "STOP",
          "index" => 0
        }
      ]
    }
  end

  let(:chunk_with_metrics) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              {
                "text" => "final text"
              }
            ],
            "role" => "model"
          },
          "finishReason" => "STOP",
          "index" => 0
        }
      ],
      "usageMetadata" => {
        "promptTokenCount" => 10,
        "candidatesTokenCount" => 20,
        "totalTokenCount" => 30
      }
    }
  end

  let(:empty_chunk) do
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [],
            "role" => "model"
          },
          "index" => 0
        }
      ]
    }
  end

  describe "#initialize" do
    it "initializes with a raw chunk" do
      response = described_class.new(regular_chunk)
      expect(response.raw_chunk).to eq(regular_chunk)
    end
  end

  describe "#parse_chunk" do
    it "extracts text from a regular chunk" do
      response = described_class.new(regular_chunk)
      expect(response.text).to eq("Hello, ")
    end

    it "extracts text and finish reason from a final chunk" do
      response = described_class.new(final_chunk)
      expect(response.text).to eq("world!")
      expect(response.finish_reason).to eq("STOP")
    end

    it "extracts text, finish reason, and usage metrics" do
      response = described_class.new(chunk_with_metrics)
      expect(response.text).to eq("final text")
      expect(response.finish_reason).to eq("STOP")
      expect(response.usage_metrics).to eq(chunk_with_metrics["usageMetadata"])
    end

    it "handles empty parts" do
      response = described_class.new(empty_chunk)
      expect(response.text).to be_nil
    end
  end

  describe "#final_chunk?" do
    it "returns true for the final chunk" do
      response = described_class.new(final_chunk)
      expect(response).to be_final_chunk
    end

    it "returns false for a regular chunk" do
      response = described_class.new(regular_chunk)
      expect(response).not_to be_final_chunk
    end
  end

  describe "#has_usage_metrics?" do
    it "returns true when usage metrics are present" do
      response = described_class.new(chunk_with_metrics)
      expect(response).to have_usage_metrics
    end

    it "returns false when usage metrics are absent" do
      response = described_class.new(regular_chunk)
      expect(response).not_to have_usage_metrics
    end
  end

  describe "#prompt_tokens" do
    it "returns the prompt token count when available" do
      response = described_class.new(chunk_with_metrics)
      expect(response.prompt_tokens).to eq(10)
    end

    it "returns nil when usage metrics are absent" do
      response = described_class.new(regular_chunk)
      expect(response.prompt_tokens).to be_nil
    end
  end

  describe "#completion_tokens" do
    it "returns the completion token count when available" do
      response = described_class.new(chunk_with_metrics)
      expect(response.completion_tokens).to eq(20)
    end

    it "returns nil when usage metrics are absent" do
      response = described_class.new(regular_chunk)
      expect(response.completion_tokens).to be_nil
    end
  end

  describe "#total_tokens" do
    it "returns the total token count when available" do
      response = described_class.new(chunk_with_metrics)
      expect(response.total_tokens).to eq(30)
    end

    it "returns nil when usage metrics are absent" do
      response = described_class.new(regular_chunk)
      expect(response.total_tokens).to be_nil
    end
  end

  describe ".from_hash" do
    it "creates a StreamResponse from a hash" do
      response = described_class.from_hash(regular_chunk)
      expect(response).to be_a(described_class)
      expect(response.raw_chunk).to eq(regular_chunk)
    end
  end

  describe "unusual edge cases" do
    it "handles chunks with multiple text parts" do
      chunk_with_multiple_parts = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {"text" => "Hello"},
                {"text" => "world"}
              ],
              "role" => "model"
            },
            "index" => 0
          }
        ]
      }

      response = described_class.new(chunk_with_multiple_parts)
      expect(response.text).to eq("Hello world")
    end

    it "handles chunks with nil text parts" do
      chunk_with_nil_parts = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {"text" => nil},
                {"text" => "world"}
              ],
              "role" => "model"
            },
            "index" => 0
          }
        ]
      }

      response = described_class.new(chunk_with_nil_parts)
      expect(response.text).to eq("world")
    end

    it "handles chunks with no candidates" do
      chunk_without_candidates = {}

      response = described_class.new(chunk_without_candidates)
      expect(response.text).to be_nil
      expect(response.finish_reason).to be_nil
    end
  end
end
