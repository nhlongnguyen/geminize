# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::CodeExecution::CodeExecutionResult do
  let(:outcome) { "OUTCOME_OK" }
  let(:output) { "Hello, World!\n" }
  let(:code_execution_result) { described_class.new(outcome, output) }

  describe "#initialize" do
    it "initializes with valid outcome and output" do
      expect(code_execution_result.outcome).to eq(outcome)
      expect(code_execution_result.output).to eq(output)
    end

    it "raises an error when outcome is nil" do
      expect { described_class.new(nil, output) }
        .to raise_error(Geminize::ValidationError, /Outcome must be a string/)
    end

    it "raises an error when outcome is invalid" do
      expect { described_class.new("INVALID_OUTCOME", output) }
        .to raise_error(Geminize::ValidationError, /Invalid outcome/)
    end

    it "raises an error when output is nil" do
      expect { described_class.new(outcome, nil) }
        .to raise_error(Geminize::ValidationError, /Output must be a string/)
    end

    it "raises an error when output is not a string" do
      expect { described_class.new(outcome, 123) }
        .to raise_error(Geminize::ValidationError, /Output must be a string/)
    end
  end

  describe "#validate!" do
    it "returns true for valid code execution result" do
      expect(code_execution_result.validate!).to be(true)
    end
  end

  describe "#to_hash and #to_h" do
    it "returns a hash with correct keys and values" do
      expected_hash = {
        outcome: outcome,
        output: output
      }
      expect(code_execution_result.to_hash).to eq(expected_hash)
      expect(code_execution_result.to_h).to eq(expected_hash)
    end
  end

  describe "with error outcome" do
    let(:outcome) { "OUTCOME_ERROR" }
    let(:output) { "Error: Division by zero" }

    it "initializes with error outcome" do
      expect(code_execution_result.outcome).to eq(outcome)
      expect(code_execution_result.output).to eq(output)
    end
  end
end
