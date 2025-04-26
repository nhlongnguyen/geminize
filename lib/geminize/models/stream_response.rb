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

      # @return [Hash, nil] Token usage metrics (only available in final chunk)
      attr_reader :usage_metrics

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

      # Check if this chunk has usage metrics
      # @return [Boolean] True if this chunk contains usage metrics
      def has_usage_metrics?
        !@usage_metrics.nil?
      end

      # Get the prompt token count if available
      # @return [Integer, nil] Prompt token count or nil if not available
      def prompt_tokens
        return nil unless @usage_metrics
        @usage_metrics["promptTokenCount"]
      end

      # Get the completion token count if available
      # @return [Integer, nil] Completion token count or nil if not available
      def completion_tokens
        return nil unless @usage_metrics
        @usage_metrics["candidatesTokenCount"]
      end

      # Get the total token count if available
      # @return [Integer, nil] Total token count or nil if not available
      def total_tokens
        return nil unless @usage_metrics
        (prompt_tokens || 0) + (completion_tokens || 0)
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
        @usage_metrics = nil

        # First check if the response has the expected fields
        if @raw_chunk.is_a?(Hash)
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

          # Extract usage metrics if available
          if @raw_chunk["usageMetadata"]
            @usage_metrics = @raw_chunk["usageMetadata"]
          end
        end
      end
    end
  end
end
