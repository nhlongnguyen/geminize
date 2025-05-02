# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentResponse do
  describe "function calling extensions" do
    let(:function_call_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "functionCall" => {
                    "name" => "get_weather",
                    "args" => {
                      "location" => "New York, NY"
                    }
                  }
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "promptFeedback" => {
          "blockReason" => nil,
          "safetyRatings" => []
        }
      }
    end

    let(:text_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "The weather in New York is sunny."
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "promptFeedback" => {
          "blockReason" => nil,
          "safetyRatings" => []
        }
      }
    end

    let(:json_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "{\"temperature\": 22, \"conditions\": \"Sunny\", \"humidity\": 45}"
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "promptFeedback" => {
          "blockReason" => nil,
          "safetyRatings" => []
        }
      }
    end

    describe "#function_call" do
      it "returns a FunctionResponse when response contains a function call" do
        response = described_class.new(function_call_response)

        expect(response.function_call).to be_a(Geminize::Models::FunctionResponse)
        expect(response.function_call.name).to eq("get_weather")
        expect(response.function_call.response).to eq({"location" => "New York, NY"})
      end

      it "returns nil when response doesn't contain a function call" do
        response = described_class.new(text_response)

        expect(response.function_call).to be_nil
      end

      it "memoizes the function call" do
        response = described_class.new(function_call_response)

        # Call function_call twice
        first_call = response.function_call
        second_call = response.function_call

        # Should be the same object
        expect(first_call).to be(second_call)
      end
    end

    describe "#has_function_call?" do
      it "returns true when response contains a function call" do
        response = described_class.new(function_call_response)

        expect(response.has_function_call?).to be true
      end

      it "returns false when response doesn't contain a function call" do
        response = described_class.new(text_response)

        expect(response.has_function_call?).to be false
      end
    end

    describe "#json_response" do
      it "returns parsed JSON when response contains valid JSON" do
        response = described_class.new(json_response)

        expect(response.json_response).to be_a(Hash)
        expect(response.json_response["temperature"]).to eq(22)
        expect(response.json_response["conditions"]).to eq("Sunny")
        expect(response.json_response["humidity"]).to eq(45)
      end

      it "returns nil when response doesn't contain valid JSON" do
        response = described_class.new(text_response)

        expect(response.json_response).to be_nil
      end

      it "memoizes the JSON response" do
        response = described_class.new(json_response)

        # Call json_response twice
        first_call = response.json_response
        second_call = response.json_response

        # Should be the same object
        expect(first_call).to be(second_call)
      end
    end

    describe "#has_json_response?" do
      it "returns true when response contains valid JSON" do
        response = described_class.new(json_response)

        expect(response.has_json_response?).to be true
      end

      it "returns false when response doesn't contain valid JSON" do
        response = described_class.new(text_response)

        expect(response.has_json_response?).to be false
      end
    end
  end
end
