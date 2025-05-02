# frozen_string_literal: true

module Geminize
  module Models
    # Extends ContentRequest with safety settings support
    class ContentRequest
      # @return [Array<Geminize::Models::SafetySetting>] The safety settings for this request
      attr_reader :safety_settings

      # Add a safety setting to the request
      # @param category [String] The harm category this setting applies to
      # @param threshold [String] The threshold level for filtering
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the safety setting is invalid
      def add_safety_setting(category, threshold)
        @safety_settings ||= []

        safety_setting = SafetySetting.new(category, threshold)
        @safety_settings << safety_setting

        self
      end

      # Set default safety settings for all harm categories
      # @param threshold [String] The threshold level to apply to all categories
      # @return [self] The request object for chaining
      # @raise [Geminize::ValidationError] If the threshold is invalid
      def set_default_safety_settings(threshold)
        @safety_settings = []

        SafetySetting::HARM_CATEGORIES.each do |category|
          add_safety_setting(category, threshold)
        end

        self
      end

      # Block all harmful content (most conservative setting)
      # @return [self] The request object for chaining
      def block_all_harmful_content
        set_default_safety_settings("BLOCK_LOW_AND_ABOVE")
      end

      # Block only high-risk content (least conservative setting)
      # @return [self] The request object for chaining
      def block_only_high_risk_content
        set_default_safety_settings("BLOCK_ONLY_HIGH")
      end

      # Remove all safety settings (use with caution)
      # @return [self] The request object for chaining
      def remove_safety_settings
        @safety_settings = []
        self
      end

      # Get the base to_hash method - this will use the one defined in content_request_extensions.rb if available
      alias_method :safety_original_to_hash, :to_hash unless method_defined?(:safety_original_to_hash)

      # Override the to_hash method to include safety settings
      # @return [Hash] The request as a hash
      def to_hash
        # Get the base hash (will include tools if that extension is loaded)
        request = defined?(original_to_hash) ? original_to_hash : safety_original_to_hash

        # Add safety settings if present
        if @safety_settings && !@safety_settings.empty?
          request[:safetySettings] = @safety_settings.map(&:to_hash)
        end

        request
      end

      # Validate method for safety settings - should only be called if not overridden by content_request_extensions.rb
      # If that file's validate! is called, it should also call validate_safety_settings!
      def validate!
        # Don't call super, instead call the necessary validations directly
        # Check if original_validate! is defined from the extensions
        if defined?(original_validate!)
          original_validate!
        else
          # Call the original internal validation methods
          validate_prompt!
          validate_system_instruction! if @system_instruction
          validate_temperature! if @temperature
          validate_max_tokens! if @max_tokens
          validate_top_p! if @top_p
          validate_top_k! if @top_k
          validate_stop_sequences! if @stop_sequences
          validate_content_parts!
        end

        # Add our safety validation
        validate_safety_settings!
        true
      end

      private

      # Validate the safety settings
      # @raise [Geminize::ValidationError] If the safety settings are invalid
      def validate_safety_settings!
        return if @safety_settings.nil? || @safety_settings.empty?

        unless @safety_settings.is_a?(Array)
          raise Geminize::ValidationError.new(
            "Safety settings must be an array, got #{@safety_settings.class}",
            "INVALID_ARGUMENT"
          )
        end

        @safety_settings.each_with_index do |setting, index|
          unless setting.is_a?(SafetySetting)
            raise Geminize::ValidationError.new(
              "Safety setting at index #{index} must be a SafetySetting, got #{setting.class}",
              "INVALID_ARGUMENT"
            )
          end
        end
      end
    end
  end
end
