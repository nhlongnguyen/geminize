# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentResponse do
  describe "code execution parsing" do
    let(:text_content) { "Here is the result of the code execution." }
    let(:language) { "PYTHON" }
    let(:code) { "def is_prime(n):\n    if n <= 1:\n        return False\n    for i in range(2, int(n**0.5) + 1):\n        if n % i == 0:\n            return False\n    return True\n\nprimes = [n for n in range(2, 50) if is_prime(n)]\nprint(f\"First 10 prime numbers: {primes[:10]}\")" }
    let(:execution_output) { "First 10 prime numbers: [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]" }

    let(:response_data_with_code_execution) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {"text" => text_content},
                {
                  "executableCode" => {
                    "language" => language,
                    "code" => code
                  }
                },
                {
                  "codeExecutionResult" => {
                    "outcome" => "OUTCOME_OK",
                    "output" => execution_output
                  }
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

    subject { described_class.new(response_data_with_code_execution) }

    it "correctly parses executable code" do
      expect(subject.has_executable_code?).to be true
      expect(subject.executable_code).to be_a(Geminize::Models::CodeExecution::ExecutableCode)
      expect(subject.executable_code.language).to eq(language)
      expect(subject.executable_code.code).to eq(code)
    end

    it "correctly parses code execution result" do
      expect(subject.has_code_execution_result?).to be true
      expect(subject.code_execution_result).to be_a(Geminize::Models::CodeExecution::CodeExecutionResult)
      expect(subject.code_execution_result.outcome).to eq("OUTCOME_OK")
      expect(subject.code_execution_result.output).to eq(execution_output)
    end

    it "still provides regular text content" do
      expect(subject.text).to include(text_content)
    end
  end

  describe "with error outcome" do
    let(:response_data_with_error) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {"text" => "There was an error in the code execution."},
                {
                  "executableCode" => {
                    "language" => "PYTHON",
                    "code" => "print(10/0)"
                  }
                },
                {
                  "codeExecutionResult" => {
                    "outcome" => "OUTCOME_ERROR",
                    "output" => "ZeroDivisionError: division by zero"
                  }
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

    subject { described_class.new(response_data_with_error) }

    it "correctly parses error outcomes" do
      expect(subject.has_code_execution_result?).to be true
      expect(subject.code_execution_result.outcome).to eq("OUTCOME_ERROR")
      expect(subject.code_execution_result.output).to include("ZeroDivisionError")
    end
  end

  describe "without code execution" do
    let(:response_data_without_code) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {"text" => "This is a regular text response without code execution."}
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ]
      }
    end

    subject { described_class.new(response_data_without_code) }

    it "has no executable code" do
      expect(subject.has_executable_code?).to be false
      expect(subject.executable_code).to be_nil
    end

    it "has no code execution result" do
      expect(subject.has_code_execution_result?).to be false
      expect(subject.code_execution_result).to be_nil
    end
  end
end
