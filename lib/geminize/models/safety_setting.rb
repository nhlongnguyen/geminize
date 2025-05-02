# frozen_string_literal: true

module Geminize
  module Models
    # Represents a safety setting for content filtering in Gemini API
    class SafetySetting
      # Valid harm categories for safety settings
      HARM_CATEGORIES = [
        "HARM_CATEGORY_HARASSMENT",
        "HARM_CATEGORY_HATE_SPEECH",
        "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "HARM_CATEGORY_DANGEROUS_CONTENT"
      ].freeze

      # Valid threshold levels for safety settings
      THRESHOLD_LEVELS = [
        "BLOCK_NONE",
        "BLOCK_LOW_AND_ABOVE",
        "BLOCK_MEDIUM_AND_ABOVE",
        "BLOCK_ONLY_HIGH"
      ].freeze

      # @return [String] The harm category this setting applies to
      attr_reader :category

      # @return [String] The threshold level for filtering
      attr_reader :threshold

      # Initialize a new safety setting
      # @param category [String] The harm category this setting applies to
      # @param threshold [String] The threshold level for filtering
      # @raise [Geminize::ValidationError] If the safety setting is invalid
      def initialize(category, threshold)
        @category = category
        @threshold = threshold
        validate!
      end

      # Validate the safety setting
      # @raise [Geminize::ValidationError] If the safety setting is invalid
      # @return [Boolean] true if validation passes
      def validate!
        validate_category!
        validate_threshold!
        true
      end

      # Convert the safety setting to a hash for API requests
      # @return [Hash] The safety setting as a hash
      def to_hash
        {
          category: @category,
          threshold: @threshold
        }
      end

      # Alias for to_hash
      # @return [Hash] The safety setting as a hash
      def to_h
        to_hash
      end

      private

      # Validate the harm category
      # @raise [Geminize::ValidationError] If the category is invalid
      def validate_category!
        unless @category.is_a?(String)
          raise Geminize::ValidationError.new(
            "Category must be a string, got #{@category.class}",
            "INVALID_ARGUMENT"
          )
        end

        unless HARM_CATEGORIES.include?(@category)
          raise Geminize::ValidationError.new(
            "Invalid harm category: #{@category}. Must be one of: #{HARM_CATEGORIES.join(', ')}",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Validate the threshold level
      # @raise [Geminize::ValidationError] If the threshold is invalid
      def validate_threshold!
        unless @threshold.is_a?(String)
          raise Geminize::ValidationError.new(
            "Threshold must be a string, got #{@threshold.class}",
            "INVALID_ARGUMENT"
          )
        end

        unless THRESHOLD_LEVELS.include?(@threshold)
          raise Geminize::ValidationError.new(
            "Invalid threshold level: #{@threshold}. Must be one of: #{THRESHOLD_LEVELS.join(', ')}",
            "INVALID_ARGUMENT"
          )
        end
      end
    end
  end
end
