# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentRequest do
  let(:prompt) { "Tell me a story about a dragon" }
  let(:model_name) { "gemini-1.5-pro-latest" }
  let(:default_model) { "gemini-1.5-pro-latest" }

  before do
    allow(Geminize.configuration).to receive(:default_model).and_return(default_model)
  end

  describe "#initialize" do
    it "creates a request with a prompt and default model" do
      request = described_class.new(prompt)
      expect(request.prompt).to eq(prompt)
      expect(request.model_name).to eq(default_model)
    end

    it "creates a request with a custom model" do
      request = described_class.new(prompt, "gemini-1.5-flash")
      expect(request.model_name).to eq("gemini-1.5-flash")
    end

    it "sets generation parameters" do
      request = described_class.new(
        prompt,
        model_name,
        temperature: 0.7,
        max_tokens: 100,
        top_p: 0.9,
        top_k: 40,
        stop_sequences: ["THE END"]
      )

      expect(request.temperature).to eq(0.7)
      expect(request.max_tokens).to eq(100)
      expect(request.top_p).to eq(0.9)
      expect(request.top_k).to eq(40)
      expect(request.stop_sequences).to eq(["THE END"])
    end

    it "initializes content_parts with the prompt as text" do
      request = described_class.new(prompt)
      expect(request.content_parts).to eq([{type: "text", text: prompt}])
    end
  end

  describe "#validate!" do
    context "with prompt validation" do
      it "raises an error for nil prompt" do
        expect { described_class.new(nil) }.to raise_error(
          Geminize::ValidationError, "Prompt cannot be nil"
        )
      end

      it "raises an error for empty prompt" do
        expect { described_class.new("") }.to raise_error(
          Geminize::ValidationError, "Prompt cannot be empty"
        )
      end

      it "raises an error for non-string prompt" do
        expect { described_class.new(123) }.to raise_error(
          Geminize::ValidationError, "Prompt must be a string"
        )
      end
    end

    context "with temperature validation" do
      it "accepts nil temperature" do
        expect { described_class.new(prompt, model_name, temperature: nil) }.not_to raise_error
      end

      it "raises an error for non-numeric temperature" do
        expect { described_class.new(prompt, model_name, temperature: "warm") }.to raise_error(
          Geminize::ValidationError, "Temperature must be a number"
        )
      end

      it "raises an error for temperature below 0" do
        expect { described_class.new(prompt, model_name, temperature: -0.1) }.to raise_error(
          Geminize::ValidationError, "Temperature must be at least 0.0"
        )
      end

      it "raises an error for temperature above 1" do
        expect { described_class.new(prompt, model_name, temperature: 1.1) }.to raise_error(
          Geminize::ValidationError, "Temperature must be at most 1.0"
        )
      end

      it "accepts temperature at lower bound" do
        expect { described_class.new(prompt, model_name, temperature: 0.0) }.not_to raise_error
      end

      it "accepts temperature at upper bound" do
        expect { described_class.new(prompt, model_name, temperature: 1.0) }.not_to raise_error
      end
    end

    context "with max_tokens validation" do
      it "accepts nil max_tokens" do
        expect { described_class.new(prompt, model_name, max_tokens: nil) }.not_to raise_error
      end

      it "raises an error for non-integer max_tokens" do
        expect { described_class.new(prompt, model_name, max_tokens: 10.5) }.to raise_error(
          Geminize::ValidationError, "Max tokens must be an integer"
        )
      end

      it "raises an error for negative max_tokens" do
        expect { described_class.new(prompt, model_name, max_tokens: -10) }.to raise_error(
          Geminize::ValidationError, "Max tokens must be positive"
        )
      end

      it "raises an error for zero max_tokens" do
        expect { described_class.new(prompt, model_name, max_tokens: 0) }.to raise_error(
          Geminize::ValidationError, "Max tokens must be positive"
        )
      end

      it "accepts positive max_tokens" do
        expect { described_class.new(prompt, model_name, max_tokens: 100) }.not_to raise_error
      end
    end

    context "with top_p validation" do
      it "accepts nil top_p" do
        expect { described_class.new(prompt, model_name, top_p: nil) }.not_to raise_error
      end

      it "raises an error for non-numeric top_p" do
        expect { described_class.new(prompt, model_name, top_p: "high") }.to raise_error(
          Geminize::ValidationError, "Top-p must be a number"
        )
      end

      it "raises an error for top_p below 0" do
        expect { described_class.new(prompt, model_name, top_p: -0.1) }.to raise_error(
          Geminize::ValidationError, "Top-p must be at least 0.0"
        )
      end

      it "raises an error for top_p above 1" do
        expect { described_class.new(prompt, model_name, top_p: 1.1) }.to raise_error(
          Geminize::ValidationError, "Top-p must be at most 1.0"
        )
      end

      it "accepts top_p at lower bound" do
        expect { described_class.new(prompt, model_name, top_p: 0.0) }.not_to raise_error
      end

      it "accepts top_p at upper bound" do
        expect { described_class.new(prompt, model_name, top_p: 1.0) }.not_to raise_error
      end
    end

    context "with top_k validation" do
      it "accepts nil top_k" do
        expect { described_class.new(prompt, model_name, top_k: nil) }.not_to raise_error
      end

      it "raises an error for non-integer top_k" do
        expect { described_class.new(prompt, model_name, top_k: 10.5) }.to raise_error(
          Geminize::ValidationError, "Top-k must be an integer"
        )
      end

      it "raises an error for negative top_k" do
        expect { described_class.new(prompt, model_name, top_k: -10) }.to raise_error(
          Geminize::ValidationError, "Top-k must be positive"
        )
      end

      it "raises an error for zero top_k" do
        expect { described_class.new(prompt, model_name, top_k: 0) }.to raise_error(
          Geminize::ValidationError, "Top-k must be positive"
        )
      end

      it "accepts positive top_k" do
        expect { described_class.new(prompt, model_name, top_k: 40) }.not_to raise_error
      end
    end

    context "with stop_sequences validation" do
      it "accepts nil stop_sequences" do
        expect { described_class.new(prompt, model_name, stop_sequences: nil) }.not_to raise_error
      end

      it "raises an error for non-array stop_sequences" do
        expect { described_class.new(prompt, model_name, stop_sequences: "stop") }.to raise_error(
          Geminize::ValidationError, "Stop sequences must be an array"
        )
      end

      it "raises an error for non-string elements in stop_sequences" do
        expect { described_class.new(prompt, model_name, stop_sequences: ["stop", 123]) }.to raise_error(
          Geminize::ValidationError, "Stop sequences[1] must be a string"
        )
      end

      it "accepts valid stop_sequences" do
        expect { described_class.new(prompt, model_name, stop_sequences: ["THE END", "FIN"]) }.not_to raise_error
      end
    end

    context "with content_parts validation" do
      let(:request) { described_class.new(prompt) }

      it "validates content parts types" do
        request.instance_variable_set(:@content_parts, [
          {not_type: "text", text: "invalid part"}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "Content part 0 must be a hash with a :type key"
        )
      end

      it "validates text content parts" do
        request.instance_variable_set(:@content_parts, [
          {type: "text", text: ""}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "Text content for part 0 cannot be empty"
        )
      end

      it "validates content part types" do
        request.instance_variable_set(:@content_parts, [
          {type: "invalid", text: "some text"}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "Content part 0 has an invalid type: invalid"
        )
      end
    end
  end

  describe "#to_hash" do
    it "converts the request to a hash with minimal parameters" do
      request = described_class.new(prompt)
      hash = request.to_hash

      expect(hash).to include(
        contents: [
          {
            parts: [
              {
                text: prompt
              }
            ]
          }
        ]
      )
      expect(hash).not_to have_key(:generationConfig)
    end

    it "includes generation parameters when set" do
      request = described_class.new(
        prompt,
        model_name,
        temperature: 0.7,
        max_tokens: 100,
        top_p: 0.9,
        top_k: 40,
        stop_sequences: ["THE END"]
      )
      hash = request.to_hash

      expect(hash[:generationConfig]).to include(
        temperature: 0.7,
        maxOutputTokens: 100,
        topP: 0.9,
        topK: 40,
        stopSequences: ["THE END"]
      )
    end

    it "formats multimodal content correctly" do
      request = described_class.new(prompt)
      # Add a second text part to make it multimodal
      request.add_text("Additional text part")

      hash = request.to_hash

      expect(hash).to include(
        contents: [
          {
            parts: [
              {type: "text", text: prompt},
              {type: "text", text: "Additional text part"}
            ]
          }
        ]
      )
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      request = described_class.new(prompt)
      expect(request.to_h).to eq(request.to_hash)
    end
  end

  describe "#add_text" do
    let(:request) { described_class.new(prompt) }

    it "adds text content to the request" do
      request.add_text("Additional text")
      expect(request.content_parts).to include({type: "text", text: "Additional text"})
    end

    it "returns self for method chaining" do
      expect(request.add_text("More text")).to eq(request)
    end

    it "validates text content" do
      expect { request.add_text("") }.to raise_error(
        Geminize::ValidationError, "Text content cannot be empty"
      )
    end
  end

  describe "#multimodal?" do
    let(:request) { described_class.new(prompt) }

    it "returns false for a text-only request with one part" do
      expect(request.multimodal?).to be false
    end

    it "returns true when multiple text parts are added" do
      request.add_text("Another text part")
      expect(request.multimodal?).to be true
    end

    it "returns true when non-text parts are added" do
      # This assumes the placeholder methods are filled out
      allow(request).to receive(:add_image_from_file).and_return(request)

      # Simulate adding an image part
      request.instance_variable_set(:@content_parts, [
        {type: "text", text: prompt},
        {type: "image", mime_type: "image/jpeg", data: "fake_image_data"}
      ])

      expect(request.multimodal?).to be true
    end
  end
end
