# frozen_string_literal: true

module Geminize
  # Utility module for validating parameters
  module Validators
    class << self
      # Validate that a value is a string and not empty
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_string!(value, param_name)
        if value.nil?
          raise Geminize::ValidationError.new("#{param_name} cannot be nil", "INVALID_ARGUMENT")
        end

        unless value.is_a?(String)
          raise Geminize::ValidationError.new("#{param_name} must be a string", "INVALID_ARGUMENT")
        end
      end

      # Validate that a string is not empty
      # @param value [String] The string to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_not_empty!(value, param_name)
        validate_string!(value, param_name)

        if value.empty?
          raise Geminize::ValidationError.new("#{param_name} cannot be empty", "INVALID_ARGUMENT")
        end
      end

      # Validate that a value is a number in the specified range
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @param min [Numeric, nil] The minimum allowed value (inclusive)
      # @param max [Numeric, nil] The maximum allowed value (inclusive)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_numeric!(value, param_name, min: nil, max: nil)
        return if value.nil?

        unless value.is_a?(Numeric)
          raise Geminize::ValidationError.new("#{param_name} must be a number", "INVALID_ARGUMENT")
        end

        if min && value < min
          raise Geminize::ValidationError.new("#{param_name} must be at least #{min}", "INVALID_ARGUMENT")
        end

        if max && value > max
          raise Geminize::ValidationError.new("#{param_name} must be at most #{max}", "INVALID_ARGUMENT")
        end
      end

      # Validate that a value is an integer in the specified range
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @param min [Integer, nil] The minimum allowed value (inclusive)
      # @param max [Integer, nil] The maximum allowed value (inclusive)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_integer!(value, param_name, min: nil, max: nil)
        return if value.nil?

        unless value.is_a?(Integer)
          raise Geminize::ValidationError.new("#{param_name} must be an integer", "INVALID_ARGUMENT")
        end

        validate_numeric!(value, param_name, min: min, max: max)
      end

      # Validate that a value is a positive integer
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_positive_integer!(value, param_name)
        return if value.nil?

        validate_integer!(value, param_name)

        if value <= 0
          raise Geminize::ValidationError.new("#{param_name} must be positive", "INVALID_ARGUMENT")
        end
      end

      # Validate that a value is a float between 0 and 1
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_probability!(value, param_name)
        return if value.nil?

        validate_numeric!(value, param_name, min: 0.0, max: 1.0)
      end

      # Validate that a value is an array
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_array!(value, param_name)
        return if value.nil?

        unless value.is_a?(Array)
          raise Geminize::ValidationError.new("#{param_name} must be an array", "INVALID_ARGUMENT")
        end
      end

      # Validate that all elements of an array are strings
      # @param value [Array] The array to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_string_array!(value, param_name)
        return if value.nil?

        validate_array!(value, param_name)

        value.each_with_index do |item, index|
          unless item.is_a?(String)
            raise Geminize::ValidationError.new("#{param_name}[#{index}] must be a string", "INVALID_ARGUMENT")
          end
        end
      end

      # Validate that a value is one of an allowed set of values
      # @param value [Object] The value to validate
      # @param param_name [String] The name of the parameter (for error messages)
      # @param allowed_values [Array] The allowed values
      # @raise [Geminize::ValidationError] If validation fails
      # @return [void]
      def validate_allowed_values!(value, param_name, allowed_values)
        return if value.nil?

        unless allowed_values.include?(value)
          allowed_str = allowed_values.map(&:inspect).join(", ")
          raise Geminize::ValidationError.new(
            "#{param_name} must be one of: #{allowed_str}",
            "INVALID_ARGUMENT"
          )
        end
      end
    end
  end
end
