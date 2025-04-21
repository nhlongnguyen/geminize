# frozen_string_literal: true

module Geminize
  module Models
    # Represents a response from the Gemini API text generation
    class ContentResponse
      # @return [Hash] The raw API response data
      attr_reader :raw_response

      # @return [String, nil] The reason why generation stopped (if applicable)
      attr_reader :finish_reason

      # @return [Hash, nil] Token counts for the request and response
      attr_reader :usage

      # Initialize a new content generation response
      # @param response_data [Hash] The raw API response
      def initialize(response_data)
        @raw_response = response_data
        parse_response
      end

      # Get the generated text from the response
      # @return [String, nil] The generated text or nil if no text was generated
      def text
        return @text if defined?(@text)

        @text = nil
        candidates = @raw_response["candidates"]
        if candidates && !candidates.empty?
          content = candidates.first["content"]
          if content && content["parts"] && !content["parts"].empty?
            parts_text = content["parts"].map { |part| part["text"] }.compact
            @text = parts_text.join(" ") unless parts_text.empty?
          end
        end
        @text
      end

      # Check if the response has generated text
      # @return [Boolean] True if the response has generated text
      def has_text?
        !text.nil? && !text.empty?
      end

      # Get the total token count
      # @return [Integer, nil] Total token count or nil if not available
      def total_tokens
        return nil unless @usage

        (@usage["promptTokenCount"] || 0) + (@usage["candidatesTokenCount"] || 0)
      end

      # Get the prompt token count
      # @return [Integer, nil] Prompt token count or nil if not available
      def prompt_tokens
        return nil unless @usage

        @usage["promptTokenCount"]
      end

      # Get the completion token count
      # @return [Integer, nil] Completion token count or nil if not available
      def completion_tokens
        return nil unless @usage

        @usage["candidatesTokenCount"]
      end

      # Create a ContentResponse object from a raw API response
      # @param response_data [Hash] The raw API response
      # @return [ContentResponse] A new ContentResponse object
      def self.from_hash(response_data)
        new(response_data)
      end

      private

      # Parse the response data and extract relevant information
      def parse_response
        parse_finish_reason
        parse_usage
      end

      # Parse the finish reason from the response
      def parse_finish_reason
        candidates = @raw_response["candidates"]
        if candidates && !candidates.empty? && candidates.first["finishReason"]
          @finish_reason = candidates.first["finishReason"]
        end
      end

      # Parse usage information from the response
      def parse_usage
        @usage = @raw_response["usageMetadata"] if @raw_response["usageMetadata"]
      end
    end
  end
end
