# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::SafetySetting do
  let(:valid_category) { "HARM_CATEGORY_HARASSMENT" }
  let(:valid_threshold) { "BLOCK_MEDIUM_AND_ABOVE" }

  describe "#initialize" do
    it "creates a valid safety setting" do
      safety_setting = described_class.new(valid_category, valid_threshold)

      expect(safety_setting.category).to eq(valid_category)
      expect(safety_setting.threshold).to eq(valid_threshold)
    end

    it "raises an error when category is not a string" do
      expect {
        described_class.new(123, valid_threshold)
      }.to raise_error(Geminize::ValidationError, /Category must be a string/i)
    end

    it "raises an error when category is invalid" do
      expect {
        described_class.new("INVALID_CATEGORY", valid_threshold)
      }.to raise_error(Geminize::ValidationError, /Invalid harm category/i)
    end

    it "raises an error when threshold is not a string" do
      expect {
        described_class.new(valid_category, 123)
      }.to raise_error(Geminize::ValidationError, /Threshold must be a string/i)
    end

    it "raises an error when threshold is invalid" do
      expect {
        described_class.new(valid_category, "INVALID_THRESHOLD")
      }.to raise_error(Geminize::ValidationError, /Invalid threshold level/i)
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the safety setting" do
      safety_setting = described_class.new(valid_category, valid_threshold)
      hash = safety_setting.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:category]).to eq(valid_category)
      expect(hash[:threshold]).to eq(valid_threshold)
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      safety_setting = described_class.new(valid_category, valid_threshold)

      expect(safety_setting.to_h).to eq(safety_setting.to_hash)
    end
  end

  describe "HARM_CATEGORIES" do
    it "defines all valid harm categories" do
      expect(described_class::HARM_CATEGORIES).to eq([
        "HARM_CATEGORY_HARASSMENT",
        "HARM_CATEGORY_HATE_SPEECH",
        "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "HARM_CATEGORY_DANGEROUS_CONTENT"
      ])
    end
  end

  describe "THRESHOLD_LEVELS" do
    it "defines all valid threshold levels" do
      expect(described_class::THRESHOLD_LEVELS).to eq([
        "BLOCK_NONE",
        "BLOCK_LOW_AND_ABOVE",
        "BLOCK_MEDIUM_AND_ABOVE",
        "BLOCK_ONLY_HIGH"
      ])
    end
  end
end
