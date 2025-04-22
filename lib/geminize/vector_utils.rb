# frozen_string_literal: true

module Geminize
  # Utility module for vector operations used with embeddings
  module VectorUtils
    class << self
      # Calculate the cosine similarity between two vectors
      # @param vec1 [Array<Float>] First vector
      # @param vec2 [Array<Float>] Second vector
      # @return [Float] Cosine similarity (-1 to 1)
      # @raise [Geminize::ValidationError] If vectors have different dimensions
      def cosine_similarity(vec1, vec2)
        unless vec1.length == vec2.length
          raise Geminize::ValidationError.new(
            "Vectors must have the same dimensions (#{vec1.length} vs #{vec2.length})",
            "INVALID_ARGUMENT"
          )
        end

        dot_product = 0.0
        magnitude1 = 0.0
        magnitude2 = 0.0

        vec1.zip(vec2).each do |v1, v2|
          dot_product += v1 * v2
          magnitude1 += v1 * v1
          magnitude2 += v2 * v2
        end

        magnitude1 = Math.sqrt(magnitude1)
        magnitude2 = Math.sqrt(magnitude2)

        # Guard against division by zero
        return 0.0 if magnitude1.zero? || magnitude2.zero?

        dot_product / (magnitude1 * magnitude2)
      end

      # Calculate the Euclidean distance between two vectors
      # @param vec1 [Array<Float>] First vector
      # @param vec2 [Array<Float>] Second vector
      # @return [Float] Euclidean distance
      # @raise [Geminize::ValidationError] If vectors have different dimensions
      def euclidean_distance(vec1, vec2)
        unless vec1.length == vec2.length
          raise Geminize::ValidationError.new(
            "Vectors must have the same dimensions (#{vec1.length} vs #{vec2.length})",
            "INVALID_ARGUMENT"
          )
        end

        sum_square_diff = 0.0
        vec1.zip(vec2).each do |v1, v2|
          diff = v1 - v2
          sum_square_diff += diff * diff
        end

        Math.sqrt(sum_square_diff)
      end

      # Calculate the dot product of two vectors
      # @param vec1 [Array<Float>] First vector
      # @param vec2 [Array<Float>] Second vector
      # @return [Float] Dot product
      # @raise [Geminize::ValidationError] If vectors have different dimensions
      def dot_product(vec1, vec2)
        unless vec1.length == vec2.length
          raise Geminize::ValidationError.new(
            "Vectors must have the same dimensions (#{vec1.length} vs #{vec2.length})",
            "INVALID_ARGUMENT"
          )
        end

        product = 0.0
        vec1.zip(vec2).each do |v1, v2|
          product += v1 * v2
        end

        product
      end

      # Normalize a vector to unit length
      # @param vec [Array<Float>] Vector to normalize
      # @return [Array<Float>] Normalized vector
      def normalize(vec)
        magnitude = 0.0
        vec.each do |v|
          magnitude += v * v
        end
        magnitude = Math.sqrt(magnitude)

        # Handle zero magnitude vector
        return vec.map { 0.0 } if magnitude.zero?

        vec.map { |v| v / magnitude }
      end

      # Average multiple vectors
      # @param vectors [Array<Array<Float>>] Array of vectors
      # @return [Array<Float>] Average vector
      # @raise [Geminize::ValidationError] If vectors have different dimensions or no vectors provided
      def average_vectors(vectors)
        if vectors.empty?
          raise Geminize::ValidationError.new(
            "Cannot average an empty array of vectors",
            "INVALID_ARGUMENT"
          )
        end

        # Check all vectors have same dimensionality
        dim = vectors.first.length
        vectors.each_with_index do |vec, i|
          unless vec.length == dim
            raise Geminize::ValidationError.new(
              "All vectors must have the same dimensions (expected #{dim}, got #{vec.length} at index #{i})",
              "INVALID_ARGUMENT"
            )
          end
        end

        # Calculate average
        avg = Array.new(dim, 0.0)
        vectors.each do |vec|
          vec.each_with_index do |v, i|
            avg[i] += v
          end
        end

        avg.map { |sum| sum / vectors.length }
      end

      # Find the most similar vectors to a target vector
      # @param target [Array<Float>] Target vector
      # @param vectors [Array<Array<Float>>] Vectors to compare against
      # @param top_k [Integer, nil] Number of most similar vectors to return
      # @param metric [Symbol] Distance metric to use (:cosine or :euclidean)
      # @return [Array<Hash>] Array of {index:, similarity:} hashes sorted by similarity
      def most_similar(target, vectors, top_k = nil, metric = :cosine)
        similarities = []

        vectors.each_with_index do |vec, i|
          similarity = case metric
          when :cosine
            cosine_similarity(target, vec)
          when :euclidean
            # Convert to similarity (higher is more similar)
            1.0 / (1.0 + euclidean_distance(target, vec))
          else
            raise Geminize::ValidationError.new(
              "Unknown metric: #{metric}. Supported metrics: :cosine, :euclidean",
              "INVALID_ARGUMENT"
            )
          end

          similarities << {index: i, similarity: similarity}
        end

        # Sort by similarity (descending)
        sorted = similarities.sort_by { |s| -s[:similarity] }
        top_k ? sorted.take(top_k) : sorted
      end
    end
  end
end
