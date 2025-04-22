# frozen_string_literal: true

module Geminize
  module Models
    # Represents a streaming response chunk from the Gemini API
    class StreamResponse
      # @return [Hash] The raw API response data for this chunk
      attr_reader :raw_chunk

      # @return [String, nil] The text content in this chunk
      attr_reader :text

      # @return [String, nil] The finish reason if this is the last chunk
      attr_reader :finish_reason

      # Initialize a new streaming response chunk
      # @param chunk_data [Hash] The raw API response chunk
      def initialize(chunk_data)
        @raw_chunk = chunk_data
        parse_chunk
      end

      # Check if this is the final chunk in the stream
      # @return [Boolean] True if this is the final chunk
      def final_chunk?
        !@finish_reason.nil?
      end

      # Create a StreamResponse object from a raw API response chunk
      # @param chunk_data [Hash] The raw API response chunk
      # @return [StreamResponse] A new StreamResponse object
      def self.from_hash(chunk_data)
        new(chunk_data)
      end

      private

      # Parse the chunk data and extract relevant information
      def parse_chunk
        @text = nil
        @finish_reason = nil

        candidates = @raw_chunk["candidates"]
        if candidates && !candidates.empty?
          # Extract finish reason if available (last chunk)
          if candidates.first["finishReason"]
            @finish_reason = candidates.first["finishReason"]
          end

          # Extract text content if available
          content = candidates.first["content"]
          if content && content["parts"] && !content["parts"].empty?
            parts_text = content["parts"].map { |part| part["text"] }.compact
            @text = parts_text.join(" ") unless parts_text.empty?
          end
        end
      end
    end
  end
end
