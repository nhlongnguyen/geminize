# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Validators do
  describe ".validate_string!" do
    it "passes for valid strings" do
      expect { described_class.validate_string!("valid", "test") }.not_to raise_error
    end

    it "raises error for nil values" do
      expect { described_class.validate_string!(nil, "test") }.to raise_error(
        Geminize::ValidationError, "test cannot be nil"
      )
    end

    it "raises error for non-string values" do
      expect { described_class.validate_string!(123, "test") }.to raise_error(
        Geminize::ValidationError, "test must be a string"
      )
    end
  end

  describe ".validate_not_empty!" do
    it "passes for non-empty strings" do
      expect { described_class.validate_not_empty!("valid", "test") }.not_to raise_error
    end

    it "raises error for empty strings" do
      expect { described_class.validate_not_empty!("", "test") }.to raise_error(
        Geminize::ValidationError, "test cannot be empty"
      )
    end

    it "raises error for nil values" do
      expect { described_class.validate_not_empty!(nil, "test") }.to raise_error(
        Geminize::ValidationError, "test cannot be nil"
      )
    end

    it "raises error for non-string values" do
      expect { described_class.validate_not_empty!(123, "test") }.to raise_error(
        Geminize::ValidationError, "test must be a string"
      )
    end
  end

  describe ".validate_numeric!" do
    it "passes for valid numbers" do
      expect { described_class.validate_numeric!(42, "test") }.not_to raise_error
      expect { described_class.validate_numeric!(3.14, "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_numeric!(nil, "test") }.not_to raise_error
    end

    it "raises error for non-numeric values" do
      expect { described_class.validate_numeric!("not a number", "test") }.to raise_error(
        Geminize::ValidationError, "test must be a number"
      )
    end

    it "validates minimum value" do
      expect { described_class.validate_numeric!(5, "test", min: 10) }.to raise_error(
        Geminize::ValidationError, "test must be at least 10"
      )
    end

    it "validates maximum value" do
      expect { described_class.validate_numeric!(15, "test", max: 10) }.to raise_error(
        Geminize::ValidationError, "test must be at most 10"
      )
    end
  end

  describe ".validate_integer!" do
    it "passes for valid integers" do
      expect { described_class.validate_integer!(42, "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_integer!(nil, "test") }.not_to raise_error
    end

    it "raises error for non-integer values" do
      expect { described_class.validate_integer!(3.14, "test") }.to raise_error(
        Geminize::ValidationError, "test must be an integer"
      )
    end

    it "validates minimum value" do
      expect { described_class.validate_integer!(5, "test", min: 10) }.to raise_error(
        Geminize::ValidationError, "test must be at least 10"
      )
    end

    it "validates maximum value" do
      expect { described_class.validate_integer!(15, "test", max: 10) }.to raise_error(
        Geminize::ValidationError, "test must be at most 10"
      )
    end
  end

  describe ".validate_positive_integer!" do
    it "passes for positive integers" do
      expect { described_class.validate_positive_integer!(42, "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_positive_integer!(nil, "test") }.not_to raise_error
    end

    it "raises error for zero" do
      expect { described_class.validate_positive_integer!(0, "test") }.to raise_error(
        Geminize::ValidationError, "test must be positive"
      )
    end

    it "raises error for negative integers" do
      expect { described_class.validate_positive_integer!(-5, "test") }.to raise_error(
        Geminize::ValidationError, "test must be positive"
      )
    end

    it "raises error for non-integers" do
      expect { described_class.validate_positive_integer!(3.14, "test") }.to raise_error(
        Geminize::ValidationError, "test must be an integer"
      )
    end
  end

  describe ".validate_probability!" do
    it "passes for values between 0 and 1" do
      expect { described_class.validate_probability!(0.0, "test") }.not_to raise_error
      expect { described_class.validate_probability!(0.5, "test") }.not_to raise_error
      expect { described_class.validate_probability!(1.0, "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_probability!(nil, "test") }.not_to raise_error
    end

    it "raises error for values below 0" do
      expect { described_class.validate_probability!(-0.1, "test") }.to raise_error(
        Geminize::ValidationError, "test must be at least 0.0"
      )
    end

    it "raises error for values above 1" do
      expect { described_class.validate_probability!(1.1, "test") }.to raise_error(
        Geminize::ValidationError, "test must be at most 1.0"
      )
    end

    it "raises error for non-numeric values" do
      expect { described_class.validate_probability!("not a number", "test") }.to raise_error(
        Geminize::ValidationError, "test must be a number"
      )
    end
  end

  describe ".validate_array!" do
    it "passes for arrays" do
      expect { described_class.validate_array!([], "test") }.not_to raise_error
      expect { described_class.validate_array!([1, 2, 3], "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_array!(nil, "test") }.not_to raise_error
    end

    it "raises error for non-arrays" do
      expect { described_class.validate_array!("not an array", "test") }.to raise_error(
        Geminize::ValidationError, "test must be an array"
      )
    end
  end

  describe ".validate_string_array!" do
    it "passes for arrays of strings" do
      expect { described_class.validate_string_array!([], "test") }.not_to raise_error
      expect { described_class.validate_string_array!(["a", "b", "c"], "test") }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_string_array!(nil, "test") }.not_to raise_error
    end

    it "raises error for arrays with non-string elements" do
      expect { described_class.validate_string_array!(["a", 1, "c"], "test") }.to raise_error(
        Geminize::ValidationError, "test[1] must be a string"
      )
    end

    it "raises error for non-arrays" do
      expect { described_class.validate_string_array!("not an array", "test") }.to raise_error(
        Geminize::ValidationError, "test must be an array"
      )
    end
  end

  describe ".validate_allowed_values!" do
    let(:allowed_values) { ["one", "two", "three"] }

    it "passes for allowed values" do
      expect { described_class.validate_allowed_values!("one", "test", allowed_values) }.not_to raise_error
    end

    it "allows nil values" do
      expect { described_class.validate_allowed_values!(nil, "test", allowed_values) }.not_to raise_error
    end

    it "raises error for disallowed values" do
      expect { described_class.validate_allowed_values!("four", "test", allowed_values) }.to raise_error(
        Geminize::ValidationError, 'test must be one of: "one", "two", "three"'
      )
    end
  end
end
