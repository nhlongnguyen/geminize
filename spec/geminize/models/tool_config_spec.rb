# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ToolConfig do
  describe "#initialize" do
    it "creates a valid tool config with default execution mode" do
      tool_config = described_class.new

      expect(tool_config.execution_mode).to eq("AUTO")
    end

    it "creates a valid tool config with specified execution mode" do
      tool_config = described_class.new("MANUAL")

      expect(tool_config.execution_mode).to eq("MANUAL")
    end

    it "raises an error when execution_mode is invalid" do
      expect {
        described_class.new("INVALID_MODE")
      }.to raise_error(Geminize::ValidationError, /Invalid execution mode/i)
    end
  end

  describe "#to_hash" do
    it "returns a hash representation of the tool config" do
      tool_config = described_class.new("MANUAL")
      hash = tool_config.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:function_calling_config][:mode]).to eq("MANUAL")
    end
  end

  describe "#to_h" do
    it "is an alias for to_hash" do
      tool_config = described_class.new("NONE")

      expect(tool_config.to_h).to eq(tool_config.to_hash)
    end
  end

  describe "EXECUTION_MODES" do
    it "defines the allowed execution modes" do
      expect(described_class::EXECUTION_MODES).to eq(["AUTO", "MANUAL", "NONE"])
    end
  end
end
