# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::CodeExecution::ExecutableCode do
  let(:language) { "PYTHON" }
  let(:code) { "print('Hello, World!')" }
  let(:executable_code) { described_class.new(language, code) }

  describe "#initialize" do
    it "initializes with valid language and code" do
      expect(executable_code.language).to eq(language)
      expect(executable_code.code).to eq(code)
    end

    it "raises an error when language is nil" do
      expect { described_class.new(nil, code) }
        .to raise_error(Geminize::ValidationError, /Language must be a string/)
    end

    it "raises an error when language is invalid" do
      expect { described_class.new("INVALID_LANGUAGE", code) }
        .to raise_error(Geminize::ValidationError, /Invalid language/)
    end

    it "raises an error when code is nil" do
      expect { described_class.new(language, nil) }
        .to raise_error(Geminize::ValidationError, /Code must be a string/)
    end

    it "raises an error when code is not a string" do
      expect { described_class.new(language, 123) }
        .to raise_error(Geminize::ValidationError, /Code must be a string/)
    end
  end

  describe "#validate!" do
    it "returns true for valid executable code" do
      expect(executable_code.validate!).to be(true)
    end
  end

  describe "#to_hash and #to_h" do
    it "returns a hash with correct keys and values" do
      expected_hash = {
        language: language,
        code: code
      }
      expect(executable_code.to_hash).to eq(expected_hash)
      expect(executable_code.to_h).to eq(expected_hash)
    end
  end
end
