# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize do
  describe "safety settings extensions" do
    before do
      # Mock the TextGeneration class
      @mock_generator = instance_double(Geminize::TextGeneration)
      allow(Geminize::TextGeneration).to receive(:new).and_return(@mock_generator)

      # Configure with a dummy API key
      Geminize.configure do |config|
        config.api_key = "test-key"
        config.default_model = "test-model"
      end
    end

    after do
      Geminize.reset_configuration!
    end

    describe ".generate_with_safety_settings" do
      let(:prompt) { "Tell me about dangerous activities" }
      let(:safety_settings) do
        [
          {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
          {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE"}
        ]
      end
      let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }

      it "creates a ContentRequest with safety settings and generates content" do
        # Expect generate_with_retries to be called with a ContentRequest that has safety settings
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.safety_settings).to be_an(Array)
          expect(request.safety_settings.size).to eq(2)
          expect(request.safety_settings[0].category).to eq("HARM_CATEGORY_DANGEROUS_CONTENT")
          expect(request.safety_settings[0].threshold).to eq("BLOCK_MEDIUM_AND_ABOVE")
          expect(request.safety_settings[1].category).to eq("HARM_CATEGORY_HATE_SPEECH")
          expect(request.safety_settings[1].threshold).to eq("BLOCK_LOW_AND_ABOVE")
          expect(max_retries).to eq(3)
          expect(retry_delay).to eq(1.0)
          mock_response
        end

        result = Geminize.generate_with_safety_settings(prompt, safety_settings)
        expect(result).to be(mock_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_response
        end

        result = Geminize.generate_with_safety_settings(prompt, safety_settings, model_name)
        expect(result).to be(mock_response)
      end

      it "uses the default model when no model is provided" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq("test-model")
          mock_response
        end

        result = Geminize.generate_with_safety_settings(prompt, safety_settings)
        expect(result).to be(mock_response)
      end

      it "passes generation parameters" do
        params = {temperature: 0.5, max_tokens: 100}

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:generationConfig][:temperature]).to eq(0.5)
          expect(request.to_hash[:generationConfig][:maxOutputTokens]).to eq(100)
          mock_response
        end

        result = Geminize.generate_with_safety_settings(prompt, safety_settings, nil, params)
        expect(result).to be(mock_response)
      end

      it "uses retries by default" do
        expect(@mock_generator).to receive(:generate_with_retries).and_return(mock_response)

        result = Geminize.generate_with_safety_settings(prompt, safety_settings)
        expect(result).to be(mock_response)
      end

      it "skips retries when requested" do
        expect(@mock_generator).to receive(:generate).and_return(mock_response)
        expect(@mock_generator).not_to receive(:generate_with_retries)

        result = Geminize.generate_with_safety_settings(prompt, safety_settings, nil, {with_retries: false})
        expect(result).to be(mock_response)
      end
    end

    describe ".generate_text_safe" do
      let(:prompt) { "Tell me about dangerous activities" }
      let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }

      it "creates a ContentRequest with maximum safety settings" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.safety_settings).to be_an(Array)
          expect(request.safety_settings.size).to eq(4) # All harm categories

          # All settings should have BLOCK_LOW_AND_ABOVE threshold
          thresholds = request.safety_settings.map(&:threshold).uniq
          expect(thresholds).to eq(["BLOCK_LOW_AND_ABOVE"])

          mock_response
        end

        result = Geminize.generate_text_safe(prompt)
        expect(result).to be(mock_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_response
        end

        result = Geminize.generate_text_safe(prompt, model_name)
        expect(result).to be(mock_response)
      end

      it "passes generation parameters" do
        params = {temperature: 0.3, system_instruction: "Be very cautious"}

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:generationConfig][:temperature]).to eq(0.3)

          system_instruction = request.to_hash[:systemInstruction]
          expect(system_instruction).to be_a(Hash)
          expect(system_instruction[:parts]).to be_an(Array)
          expect(system_instruction[:parts].first[:text]).to eq("Be very cautious")

          mock_response
        end

        result = Geminize.generate_text_safe(prompt, nil, params)
        expect(result).to be(mock_response)
      end
    end

    describe ".generate_text_permissive" do
      let(:prompt) { "Tell me about dangerous activities" }
      let(:mock_response) { instance_double(Geminize::Models::ContentResponse) }

      it "creates a ContentRequest with minimum safety settings" do
        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request).to be_a(Geminize::Models::ContentRequest)
          expect(request.safety_settings).to be_an(Array)
          expect(request.safety_settings.size).to eq(4) # All harm categories

          # All settings should have BLOCK_ONLY_HIGH threshold
          thresholds = request.safety_settings.map(&:threshold).uniq
          expect(thresholds).to eq(["BLOCK_ONLY_HIGH"])

          mock_response
        end

        result = Geminize.generate_text_permissive(prompt)
        expect(result).to be(mock_response)
      end

      it "passes the model name when provided" do
        model_name = "specific-model"

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.model_name).to eq(model_name)
          mock_response
        end

        result = Geminize.generate_text_permissive(prompt, model_name)
        expect(result).to be(mock_response)
      end

      it "passes generation parameters" do
        params = {temperature: 0.9, top_p: 0.95}

        expect(@mock_generator).to receive(:generate_with_retries) do |request, max_retries, retry_delay|
          expect(request.to_hash[:generationConfig][:temperature]).to eq(0.9)
          expect(request.to_hash[:generationConfig][:topP]).to eq(0.95)
          mock_response
        end

        result = Geminize.generate_text_permissive(prompt, nil, params)
        expect(result).to be(mock_response)
      end
    end
  end
end
