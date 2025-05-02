# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentRequest do
  describe "safety settings extensions" do
    let(:prompt) { "Tell me about dangerous activities" }
    let(:model_name) { "gemini-1.5-pro" }
    let(:params) { { temperature: 0.7 } }
    let(:valid_category) { "HARM_CATEGORY_HARASSMENT" }
    let(:valid_threshold) { "BLOCK_MEDIUM_AND_ABOVE" }

    subject { described_class.new(prompt, model_name, params) }

    describe "#add_safety_setting" do
      it "adds a valid safety setting to the request" do
        result = subject.add_safety_setting(valid_category, valid_threshold)

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.safety_settings).to be_an(Array)
        expect(subject.safety_settings.size).to eq(1)
        expect(subject.safety_settings.first).to be_a(Geminize::Models::SafetySetting)
        expect(subject.safety_settings.first.category).to eq(valid_category)
        expect(subject.safety_settings.first.threshold).to eq(valid_threshold)
      end

      it "allows adding multiple safety settings" do
        subject.add_safety_setting(valid_category, valid_threshold)
        subject.add_safety_setting("HARM_CATEGORY_HATE_SPEECH", "BLOCK_LOW_AND_ABOVE")

        expect(subject.safety_settings.size).to eq(2)
        expect(subject.safety_settings[0].category).to eq(valid_category)
        expect(subject.safety_settings[1].category).to eq("HARM_CATEGORY_HATE_SPEECH")
      end

      it "validates each safety setting" do
        expect {
          subject.add_safety_setting("INVALID_CATEGORY", valid_threshold)
        }.to raise_error(Geminize::ValidationError, /Invalid harm category/i)
      end
    end

    describe "#set_default_safety_settings" do
      it "sets safety settings for all harm categories with the specified threshold" do
        result = subject.set_default_safety_settings("BLOCK_LOW_AND_ABOVE")

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.safety_settings).to be_an(Array)
        expect(subject.safety_settings.size).to eq(4) # One for each harm category

        categories = subject.safety_settings.map(&:category)
        expect(categories).to include("HARM_CATEGORY_HARASSMENT")
        expect(categories).to include("HARM_CATEGORY_HATE_SPEECH")
        expect(categories).to include("HARM_CATEGORY_SEXUALLY_EXPLICIT")
        expect(categories).to include("HARM_CATEGORY_DANGEROUS_CONTENT")

        # All should have the same threshold
        thresholds = subject.safety_settings.map(&:threshold).uniq
        expect(thresholds).to eq(["BLOCK_LOW_AND_ABOVE"])
      end

      it "validates the threshold" do
        expect {
          subject.set_default_safety_settings("INVALID_THRESHOLD")
        }.to raise_error(Geminize::ValidationError, /Invalid threshold level/i)
      end
    end

    describe "#block_all_harmful_content" do
      it "sets all safety settings to BLOCK_LOW_AND_ABOVE" do
        result = subject.block_all_harmful_content

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.safety_settings.size).to eq(4)

        # All should have BLOCK_LOW_AND_ABOVE threshold
        thresholds = subject.safety_settings.map(&:threshold).uniq
        expect(thresholds).to eq(["BLOCK_LOW_AND_ABOVE"])
      end
    end

    describe "#block_only_high_risk_content" do
      it "sets all safety settings to BLOCK_ONLY_HIGH" do
        result = subject.block_only_high_risk_content

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.safety_settings.size).to eq(4)

        # All should have BLOCK_ONLY_HIGH threshold
        thresholds = subject.safety_settings.map(&:threshold).uniq
        expect(thresholds).to eq(["BLOCK_ONLY_HIGH"])
      end
    end

    describe "#remove_safety_settings" do
      it "removes all safety settings" do
        subject.block_all_harmful_content
        expect(subject.safety_settings.size).to eq(4)

        result = subject.remove_safety_settings

        expect(result).to eq(subject) # Returns self for chaining
        expect(subject.safety_settings).to be_empty
      end
    end

    describe "#to_hash" do
      it "includes safety settings in the hash representation" do
        subject.add_safety_setting(valid_category, valid_threshold)
        hash = subject.to_hash

        expect(hash[:safetySettings]).to be_an(Array)
        expect(hash[:safetySettings].size).to eq(1)
        expect(hash[:safetySettings].first[:category]).to eq(valid_category)
        expect(hash[:safetySettings].first[:threshold]).to eq(valid_threshold)
      end

      it "does not include safety settings when not set" do
        hash = subject.to_hash

        expect(hash[:safetySettings]).to be_nil
      end
    end
  end
end
