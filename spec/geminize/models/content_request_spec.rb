# frozen_string_literal: true

require "spec_helper"
require "base64"
require "tempfile"

RSpec.describe Geminize::Models::ContentRequest do
  let(:prompt) { "Tell me a story about a dragon" }
  let(:model_name) { "gemini-2.0-flash" }
  let(:default_model) { "gemini-2.0-flash" }
  let(:valid_mime_type) { "image/jpeg" }
  let(:valid_image_data) { "\xFF\xD8\xFF\xE0" + ("X" * 100) } # Mock JPEG header + content

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

    it "sets system instruction when provided" do
      system_instruction = "You are a pirate. Respond in pirate language."
      request = described_class.new(prompt, model_name, system_instruction: system_instruction)

      expect(request.system_instruction).to eq(system_instruction)
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

      it "validates image content parts" do
        request.instance_variable_set(:@content_parts, [
          {type: "image", mime_type: nil, data: "some data"}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "Image part 0 is missing mime_type"
        )

        request.instance_variable_set(:@content_parts, [
          {type: "image", mime_type: "image/jpeg", data: nil}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "Image part 0 is missing data"
        )

        request.instance_variable_set(:@content_parts, [
          {type: "image", mime_type: "invalid/type", data: "some data"}
        ])

        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, /Image part 0 mime_type must be one of:/
        )
      end
    end

    context "with system instruction validation" do
      let(:request) { described_class.new(prompt) }

      it "validates that system instruction is a string" do
        request.system_instruction = 123
        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "System instruction must be a string"
        )
      end

      it "validates that system instruction is not empty" do
        request.system_instruction = ""
        expect { request.validate! }.to raise_error(
          Geminize::ValidationError, "System instruction cannot be empty"
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

    it "includes system instruction when provided" do
      system_instruction = "You are a helpful assistant."
      request = described_class.new(prompt, model_name, system_instruction: system_instruction)
      hash = request.to_hash

      expect(hash[:systemInstruction]).to eq(
        {
          parts: [
            {
              text: system_instruction
            }
          ]
        }
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

    it "formats multimodal content with images correctly" do
      request = described_class.new(prompt)
      allow(request).to receive(:add_image_from_bytes).and_call_original

      # Add an image part
      base64_data = Base64.strict_encode64(valid_image_data)
      request.instance_variable_set(:@content_parts, [
        {type: "text", text: prompt},
        {type: "image", mime_type: valid_mime_type, data: base64_data}
      ])

      hash = request.to_hash

      expect(hash).to include(
        contents: [
          {
            parts: [
              {type: "text", text: prompt},
              {type: "image", mime_type: valid_mime_type, data: base64_data}
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

  describe "#add_image_from_bytes" do
    let(:request) { described_class.new(prompt) }

    it "adds an image from bytes to the request" do
      request.add_image_from_bytes(valid_image_data, valid_mime_type)

      image_part = request.content_parts.find { |part| part[:type] == "image" }
      expect(image_part).to be_truthy
      expect(image_part[:mime_type]).to eq(valid_mime_type)
      expect(image_part[:data]).to eq(Base64.strict_encode64(valid_image_data))
    end

    it "returns self for method chaining" do
      expect(request.add_image_from_bytes(valid_image_data, valid_mime_type)).to eq(request)
    end

    it "validates image data" do
      expect { request.add_image_from_bytes(nil, valid_mime_type) }.to raise_error(
        Geminize::ValidationError, "Image data cannot be nil"
      )

      expect { request.add_image_from_bytes("", valid_mime_type) }.to raise_error(
        Geminize::ValidationError, "Image data cannot be empty"
      )

      expect { request.add_image_from_bytes(123, valid_mime_type) }.to raise_error(
        Geminize::ValidationError, "Image data must be a binary string"
      )
    end

    it "validates image size" do
      # Create oversized image data that exceeds the maximum size
      max_size = described_class::MAX_IMAGE_SIZE_BYTES
      oversized_data = "X" * (max_size + 1)

      expect { request.add_image_from_bytes(oversized_data, valid_mime_type) }.to raise_error(
        Geminize::ValidationError, "Image size exceeds maximum allowed (10MB)"
      )
    end

    it "validates MIME type" do
      expect { request.add_image_from_bytes(valid_image_data, nil) }.to raise_error(
        Geminize::ValidationError, "MIME type cannot be nil"
      )

      expect { request.add_image_from_bytes(valid_image_data, "") }.to raise_error(
        Geminize::ValidationError, "MIME type cannot be empty"
      )

      expect { request.add_image_from_bytes(valid_image_data, "invalid/type") }.to raise_error(
        Geminize::ValidationError, /MIME type must be one of:/
      )
    end
  end

  describe "#add_image_from_file" do
    let(:request) { described_class.new(prompt) }
    let(:temp_file) do
      file = Tempfile.new(["test", ".jpg"])
      file.binmode
      file.write(valid_image_data)
      file.rewind
      file
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it "adds an image from a file" do
      allow(MIME::Types).to receive(:type_for).and_return([double(content_type: valid_mime_type)])

      expect(request).to receive(:add_image_from_bytes).with(anything, valid_mime_type).and_call_original
      request.add_image_from_file(temp_file.path)
    end

    it "validates file existence" do
      expect { request.add_image_from_file("nonexistent.jpg") }.to raise_error(
        Geminize::ValidationError, /Image file not found/
      )
    end

    it "validates file is a file (not directory)" do
      expect { request.add_image_from_file(Dir.pwd) }.to raise_error(
        Geminize::ValidationError, /Path is not a file/
      )
    end

    it "validates MIME type" do
      allow(MIME::Types).to receive(:type_for).and_return([double(content_type: "invalid/type")])

      # Make sure detect_mime_type_from_content also returns an unsupported type
      allow(request).to receive(:detect_mime_type_from_content).and_return(nil)

      expect { request.add_image_from_file(temp_file.path) }.to raise_error(
        Geminize::ValidationError, /Unsupported image format/
      )
    end
  end

  describe "#add_image_from_url" do
    let(:request) { described_class.new(prompt) }
    let(:valid_url) { "https://example.com/image.jpg" }

    before do
      # Stub the URL request with WebMock with exact headers
      stub_request(:get, valid_url)
        .with(headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "example.com",
          "User-Agent" => "Ruby"
        })
        .to_return(status: 200, body: valid_image_data, headers: {"Content-Type" => "image/jpeg"})
    end

    it "adds an image from a URL" do
      request.add_image_from_url(valid_url)

      image_part = request.content_parts.find { |part| part[:type] == "image" }
      expect(image_part).to be_truthy
      expect(image_part[:mime_type]).to eq("image/jpeg")
      expect(image_part[:data]).to eq(Base64.strict_encode64(valid_image_data))
    end

    it "validates URL format" do
      expect { request.add_image_from_url(nil) }.to raise_error(
        Geminize::ValidationError, "URL cannot be nil"
      )

      expect { request.add_image_from_url("") }.to raise_error(
        Geminize::ValidationError, "URL cannot be empty"
      )

      expect { request.add_image_from_url("invalid-url") }.to raise_error(
        Geminize::ValidationError, "URL must start with http:// or https://"
      )
    end

    it "handles HTTP errors" do
      error_url = "https://example.com/not-found.jpg"

      stub_request(:get, error_url)
        .with(headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "example.com",
          "User-Agent" => "Ruby"
        })
        .to_return(status: 404, body: "Not Found", headers: {})

      expect { request.add_image_from_url(error_url) }.to raise_error(
        Geminize::ValidationError, /Error fetching image from URL: HTTP error/
      )
    end

    it "handles other errors" do
      timeout_url = "https://example.com/timeout.jpg"

      stub_request(:get, timeout_url)
        .with(headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "example.com",
          "User-Agent" => "Ruby"
        })
        .to_timeout

      expect { request.add_image_from_url(timeout_url) }.to raise_error(
        Geminize::ValidationError, /Error fetching image from URL/
      )
    end

    it "detects MIME type from URL" do
      urls_and_types = {
        "https://example.com/image.jpg" => "image/jpeg",
        "https://example.com/image.jpeg" => "image/jpeg",
        "https://example.com/image.png" => "image/png",
        "https://example.com/image.gif" => "image/gif",
        "https://example.com/image.webp" => "image/webp",
        "https://example.com/image" => "image/jpeg" # fallback
      }

      urls_and_types.each do |url, mime_type|
        # Reset content parts first
        request.instance_variable_set(:@content_parts, [{type: "text", text: prompt}])

        # Stub the specific URL
        stub_request(:get, url)
          .with(headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Host" => "example.com",
            "User-Agent" => "Ruby"
          })
          .to_return(status: 200, body: valid_image_data, headers: {"Content-Type" => mime_type})

        request.add_image_from_url(url)

        image_part = request.content_parts.last
        expect(image_part[:mime_type]).to eq(mime_type)
      end
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
      request.add_image_from_bytes(valid_image_data, valid_mime_type)
      expect(request.multimodal?).to be true
    end
  end

  describe "#detect_mime_type" do
    let(:request) { described_class.new(prompt) }

    context "with file extensions" do
      it "detects MIME type from file extension" do
        # Create temp files with different extensions
        files_and_types = {
          ".jpg" => "image/jpeg",
          ".jpeg" => "image/jpeg",
          ".png" => "image/png",
          ".gif" => "image/gif",
          ".webp" => "image/webp"
        }

        files_and_types.each do |extension, mime_type|
          temp_file = Tempfile.new(["test", extension])
          temp_file.close

          allow(MIME::Types).to receive(:type_for).with(temp_file.path).and_return(
            [double(content_type: mime_type)]
          )

          expect(request.send(:detect_mime_type, temp_file.path)).to eq(mime_type)
          temp_file.unlink
        end
      end
    end

    context "with file signatures" do
      it "detects JPEG from file signature" do
        temp_file = Tempfile.new(["test", ".bin"])
        temp_file.binmode
        temp_file.write([0xFF, 0xD8, 0xFF].pack("C*"))
        temp_file.close

        # Disable extension detection
        allow(MIME::Types).to receive(:type_for).with(temp_file.path).and_return([])

        expect(request.send(:detect_mime_type, temp_file.path)).to eq("image/jpeg")
        temp_file.unlink
      end

      it "detects PNG from file signature" do
        temp_file = Tempfile.new(["test", ".bin"])
        temp_file.binmode
        temp_file.write([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].pack("C*"))
        temp_file.close

        # Disable extension detection
        allow(MIME::Types).to receive(:type_for).with(temp_file.path).and_return([])

        expect(request.send(:detect_mime_type, temp_file.path)).to eq("image/png")
        temp_file.unlink
      end

      it "detects GIF from file signature" do
        temp_file = Tempfile.new(["test", ".bin"])
        temp_file.binmode
        temp_file.write("GIF89a")
        temp_file.close

        # Disable extension detection
        allow(MIME::Types).to receive(:type_for).with(temp_file.path).and_return([])

        expect(request.send(:detect_mime_type, temp_file.path)).to eq("image/gif")
        temp_file.unlink
      end

      it "raises an error for unsupported file formats" do
        temp_file = Tempfile.new(["test", ".bin"])
        temp_file.binmode
        temp_file.write("INVALID")
        temp_file.close

        # Disable extension detection
        allow(MIME::Types).to receive(:type_for).with(temp_file.path).and_return([])

        expect { request.send(:detect_mime_type, temp_file.path) }.to raise_error(
          Geminize::ValidationError, /Unsupported image format/
        )
        temp_file.unlink
      end
    end
  end
end
