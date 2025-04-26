# frozen_string_literal: true

module Geminize
  module Models
    # Represents a response from the Gemini API for an embedding request
    class EmbeddingResponse
      # @return [Hash] The raw response data from the API
      attr_reader :data

      # @return [Hash, nil] Token counts for the request and response
      attr_reader :usage

      # Initialize a new embedding response
      # @param data [Hash] The raw API response data
      # @raise [Geminize::ValidationError] If the data doesn't contain valid embeddings
      def initialize(data)
        @data = data
        validate!
        parse_response
      end

      # Get the embedding values as a flat array
      # @return [Array<Float>] The embedding values
      def values
        return @data["embedding"]["values"] if single?
        nil
      end

      # Check if the response is a batch (multiple embeddings)
      # @return [Boolean] True if the response contains multiple embeddings
      def batch?
        # Check if we have the 'embeddings' key with an array value
        @data.has_key?("embeddings") && @data["embeddings"].is_a?(Array)
      end

      # Check if the response is a single embedding (not a batch)
      # @return [Boolean] True if the response contains a single embedding
      def single?
        @data.has_key?("embedding") && @data["embedding"].is_a?(Hash) &&
          @data["embedding"].has_key?("values")
      end

      # Get all embeddings as an array of arrays
      # @return [Array<Array<Float>>] Array of embedding vectors
      def embeddings
        if single?
          [values]
        elsif batch?
          @data["embeddings"].map { |emb| emb["values"] }
        else
          []
        end
      end

      # Get the size of each embedding (vector dimension)
      # @return [Integer] The number of dimensions in each embedding
      def embedding_size
        if single?
          values.size
        elsif batch? && !@data["embeddings"].empty?
          @data["embeddings"].first["values"].size
        else
          0
        end
      end

      # Get the number of embeddings in the batch
      # @return [Integer] The number of embeddings (1 for single embedding, N for batch)
      def batch_size
        if single?
          1
        elsif batch?
          @data["embeddings"].size
        else
          0
        end
      end

      # Get a specific embedding from the batch by index
      # @param index [Integer] The index of the embedding to retrieve
      # @return [Array<Float>] The embedding values at the specified index
      # @raise [IndexError] If the index is out of bounds
      def embedding_at(index)
        if index < 0 || index >= batch_size
          raise IndexError, "Index #{index} out of bounds for batch size #{batch_size}"
        end

        if single? && index == 0
          values
        elsif batch?
          @data["embeddings"][index]["values"]
        end
      end

      # Alias for embedding_at(0)
      # @return [Array<Float>] The first embedding
      def embedding
        embedding_at(0)
      end

      # Calculate the cosine similarity between two embedding vectors
      # @param vec1 [Array<Float>] First vector
      # @param vec2 [Array<Float>] Second vector
      # @return [Float] Cosine similarity (-1 to 1)
      # @raise [Geminize::ValidationError] If vectors have different dimensions
      def self.cosine_similarity(vec1, vec2)
        Geminize::VectorUtils.cosine_similarity(vec1, vec2)
      end

      # Calculate the cosine similarity between two embedding indexes in this response
      # @param index1 [Integer] First embedding index
      # @param index2 [Integer] Second embedding index
      # @return [Float] Cosine similarity (-1 to 1)
      # @raise [Geminize::ValidationError] If the indexes are invalid
      def similarity(index1, index2)
        vec1 = embedding_at(index1)
        vec2 = embedding_at(index2)

        if vec1.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index1}", "INVALID_ARGUMENT")
        end

        if vec2.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index2}", "INVALID_ARGUMENT")
        end

        VectorUtils.cosine_similarity(vec1, vec2)
      end

      # Calculate the cosine similarity between an embedding in this response and another vector
      # @param index [Integer] Embedding index in this response
      # @param other_vector [Array<Float>] External vector to compare with
      # @return [Float] Cosine similarity (-1 to 1)
      # @raise [Geminize::ValidationError] If the index is invalid
      def similarity_with_vector(index, other_vector)
        vec = embedding_at(index)

        if vec.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index}", "INVALID_ARGUMENT")
        end

        VectorUtils.cosine_similarity(vec, other_vector)
      end

      # Compute similarity matrix for all embeddings in this response
      # @param metric [Symbol] Distance metric to use (:cosine or :euclidean)
      # @return [Array<Array<Float>>] Matrix of similarity scores
      def similarity_matrix(metric = :cosine)
        vectors = embeddings
        return [] if vectors.empty?

        matrix = Array.new(vectors.length) { Array.new(vectors.length, 0.0) }

        vectors.each_with_index do |vec1, i|
          # Diagonal is always 1 (self-similarity)
          matrix[i][i] = 1.0

          # Only compute upper triangular matrix, then copy to lower
          ((i + 1)...vectors.length).each do |j|
            vec2 = vectors[j]
            similarity = case metric
            when :cosine
              VectorUtils.cosine_similarity(vec1, vec2)
            when :euclidean
              # Convert to similarity (higher is more similar)
              1.0 / (1.0 + VectorUtils.euclidean_distance(vec1, vec2))
            else
              raise Geminize::ValidationError.new(
                "Unknown metric: #{metric}. Supported metrics: :cosine, :euclidean",
                "INVALID_ARGUMENT"
              )
            end

            matrix[i][j] = similarity
            matrix[j][i] = similarity  # Matrix is symmetric
          end
        end

        matrix
      end

      # Find the most similar embeddings to a given index
      # @param index [Integer] Index of the embedding to compare against
      # @param top_k [Integer, nil] Number of similar embeddings to return
      # @param metric [Symbol] Distance metric to use (:cosine or :euclidean)
      # @return [Array<Hash>] Array of {index:, similarity:} hashes sorted by similarity
      # @raise [Geminize::ValidationError] If the index is invalid
      def most_similar(index, top_k = nil, metric = :cosine)
        vec = embedding_at(index)
        if vec.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index}", "INVALID_ARGUMENT")
        end

        # Get all vectors except the target one
        other_vectors = embeddings.each_with_index.map { |v, i| (i == index) ? nil : v }.compact
        other_indexes = embeddings.each_with_index.map { |_, i| (i == index) ? nil : i }.compact

        # Find most similar
        similarities = VectorUtils.most_similar(vec, other_vectors, nil, metric)

        # Map back to original indexes
        similarities.each_with_index do |result, i|
          result[:index] = other_indexes[result[:index]]
        end

        # Return top k if specified
        top_k ? similarities.take(top_k) : similarities
      end

      # Normalize embeddings to unit length
      # @return [Array<Array<Float>>] Normalized embeddings
      def normalized_embeddings
        embeddings.map { |v| VectorUtils.normalize(v) }
      end

      # Average the embeddings in this response
      # @return [Array<Float>] Average embedding vector
      # @raise [Geminize::ValidationError] If there are no embeddings
      def average_embedding
        vecs = embeddings
        if vecs.empty?
          raise Geminize::ValidationError.new("No embeddings found to average", "INVALID_ARGUMENT")
        end

        VectorUtils.average_vectors(vecs)
      end

      # Calculate Euclidean distance between two embeddings
      # @param index1 [Integer] First embedding index
      # @param index2 [Integer] Second embedding index
      # @return [Float] Euclidean distance
      # @raise [Geminize::ValidationError] If the indexes are invalid
      def euclidean_distance(index1, index2)
        vec1 = embedding_at(index1)
        vec2 = embedding_at(index2)

        if vec1.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index1}", "INVALID_ARGUMENT")
        end

        if vec2.nil?
          raise Geminize::ValidationError.new("Invalid embedding index: #{index2}", "INVALID_ARGUMENT")
        end

        VectorUtils.euclidean_distance(vec1, vec2)
      end

      # Export embeddings to a JSON string
      # @param pretty [Boolean] Whether to format the JSON with indentation
      # @return [String] JSON representation of the embeddings
      def to_json(pretty = false)
        data = {
          embeddings: embeddings,
          dimensions: dimensions,
          count: embeddings.length
        }

        if pretty
          JSON.pretty_generate(data)
        else
          JSON.generate(data)
        end
      end

      # Export embeddings to a CSV string
      # @param include_header [Boolean] Whether to include a header row with dimension indices
      # @return [String] CSV representation of the embeddings
      def to_csv(include_header = true)
        return "" if embeddings.empty?

        dim = dimensions || 0
        csv_lines = []

        # Add header if requested
        if include_header
          header = (0...dim).map { |i| "dim_#{i}" }.join(",")
          csv_lines << header
        end

        # Add data rows
        embeddings.each do |vec|
          csv_lines << vec.join(",")
        end

        csv_lines.join("\n")
      end

      # Transform embeddings to a hash with specified keys
      # @param keys [Array<String>, nil] Keys to associate with each vector (must match number of embeddings)
      # @return [Hash] Hash mapping keys to embedding vectors
      # @raise [Geminize::ValidationError] If keys count doesn't match embeddings count
      def to_hash_with_keys(keys)
        vecs = embeddings

        if keys.nil?
          # Return a hash with numeric keys if no keys provided
          return vecs.each_with_index.map { |vec, i| [i.to_s, vec] }.to_h
        end

        unless keys.length == vecs.length
          raise Geminize::ValidationError.new(
            "Number of keys (#{keys.length}) doesn't match number of embeddings (#{vecs.length})",
            "INVALID_ARGUMENT"
          )
        end

        # Create hash mapping keys to vectors
        keys.zip(vecs).to_h
      end

      # Prepare data for visualization with dimensionality reduction
      # @param method [Symbol] Dimensionality reduction method (:pca or :tsne)
      # @param dimensions [Integer] Number of dimensions to reduce to (1-3)
      # @return [Array<Hash>] Array of points with reduced coordinates
      # @note This method provides the data structure for visualization but requires external
      #       libraries like 'iruby' and 'numo' to perform actual dimensionality reduction
      #       Users should transform this data according to their visualization framework
      def prepare_visualization_data(method = :pca, dimensions = 2)
        unless [:pca, :tsne].include?(method)
          raise Geminize::ValidationError.new(
            "Unknown dimensionality reduction method: #{method}. Supported methods: :pca, :tsne",
            "INVALID_ARGUMENT"
          )
        end

        unless (1..3).cover?(dimensions)
          raise Geminize::ValidationError.new(
            "Dimensions must be between 1 and 3, got: #{dimensions}",
            "INVALID_ARGUMENT"
          )
        end

        if embeddings.empty?
          return []
        end

        # This implementation just returns the structure for visualization
        # The actual dimensionality reduction should be implemented by users
        # with their preferred libraries
        embeddings.each_with_index.map do |_, i|
          {
            index: i,
            # These coordinates would normally be calculated by dimensionality reduction
            coordinates: Array.new(dimensions) { 0.0 },
            # Additional fields that would be useful for visualization
            original_vector: embedding_at(i)
          }
        end
      end

      # Get the dimensionality of the embeddings
      # @return [Integer, nil] The number of dimensions or nil if no embeddings
      def dimensions
        first = embedding
        first&.length
      end

      # Get the total token count
      # @return [Integer, nil] Total token count or nil if not available
      def total_tokens
        return nil unless @usage

        (@usage["promptTokenCount"] || 0) + (@usage["totalTokenCount"] || 0)
      end

      # Get the prompt token count
      # @return [Integer, nil] Prompt token count or nil if not available
      def prompt_tokens
        return nil unless @usage

        @usage["promptTokenCount"]
      end

      # Create an EmbeddingResponse object from a raw API response
      # @param response_data [Hash] The raw API response
      # @return [EmbeddingResponse] A new EmbeddingResponse object
      def self.from_hash(response_data)
        new(response_data)
      end

      # Export embeddings to a Numpy-compatible format
      # @return [Hash] A hash with ndarray compatible data structure
      # @note This method provides a structure that can be easily converted to
      #       a numpy array in Python or used with Ruby libraries that support
      #       numpy-compatible formats
      def to_numpy_format
        {
          data: embeddings,
          shape: [batch_size, dimensions || 0],
          dtype: "float32"
        }
      end

      # Extract top K most significant dimensions from the embeddings
      # @param k [Integer] Number of dimensions to extract
      # @return [Array<Array<Float>>] Embeddings with only the top K dimensions
      # @raise [Geminize::ValidationError] If K is greater than available dimensions
      def top_dimensions(k)
        dim = dimensions

        if dim.nil? || dim == 0
          raise Geminize::ValidationError.new("No embeddings found", "INVALID_ARGUMENT")
        end

        if k > dim
          raise Geminize::ValidationError.new(
            "Cannot extract #{k} dimensions from embeddings with only #{dim} dimensions",
            "INVALID_ARGUMENT"
          )
        end

        # This is a simplified approach that just takes the first K dimensions
        # A more sophisticated implementation would analyze variance or importance
        vecs = embeddings
        vecs.map { |vec| vec.take(k) }
      end

      # Get metadata about the embeddings
      # @return [Hash] Metadata about the embeddings including counts and token usage
      def metadata
        {
          count: batch_size,
          dimensions: dimensions,
          total_tokens: total_tokens,
          prompt_tokens: prompt_tokens,
          is_batch: batch?,
          is_single: single?
        }
      end

      # Raw response data from the API
      # @return [Hash] The complete raw API response
      def raw_response
        @data
      end

      # Iterates through each embedding with its index
      # @yield [embedding, index] Block to execute for each embedding
      # @yieldparam embedding [Array<Float>] The embedding vector
      # @yieldparam index [Integer] The index of the embedding
      # @return [Enumerator, self] Returns an enumerator if no block given, or self if block given
      def each_embedding
        return to_enum(:each_embedding) unless block_given?

        vecs = embeddings
        vecs.each_with_index do |vec, idx|
          yield vec, idx
        end

        self
      end

      # Converts embeddings to a simple array
      # @return [Array<Array<Float>>] Array of embedding vectors
      def to_a
        embeddings
      end

      # Associates labels/texts with embeddings
      # @param labels [Array<String>] Labels to associate with embeddings
      # @return [Hash] Hash mapping labels to embeddings
      # @raise [Geminize::ValidationError] If the number of labels doesn't match the number of embeddings
      def with_labels(labels)
        unless labels.is_a?(Array)
          raise Geminize::ValidationError.new("Labels must be an array", "INVALID_ARGUMENT")
        end

        vecs = embeddings
        unless labels.length == vecs.length
          raise Geminize::ValidationError.new(
            "Number of labels (#{labels.length}) doesn't match number of embeddings (#{vecs.length})",
            "INVALID_ARGUMENT"
          )
        end

        # Create hash mapping labels to vectors
        labels.zip(vecs).to_h
      end

      # Filter embeddings based on a condition
      # @yield [embedding, index] Block that returns true if the embedding should be included
      # @yieldparam embedding [Array<Float>] The embedding vector
      # @yieldparam index [Integer] The index of the embedding
      # @return [Array<Array<Float>>] Filtered embeddings
      # @note This method doesn't modify the original response object
      def filter
        return to_enum(:filter) unless block_given?

        filtered = []
        each_embedding do |vec, idx|
          filtered << vec if yield(vec, idx)
        end
        filtered
      end

      # Get a subset of embeddings by indices
      # @param start [Integer] Start index (inclusive)
      # @param finish [Integer, nil] End index (inclusive), or nil to select until the end
      # @return [Array<Array<Float>>] Subset of embeddings
      # @raise [IndexError] If the range is invalid
      def slice(start, finish = nil)
        vecs = embeddings

        # Handle negative indices
        start = vecs.length + start if start < 0
        finish = vecs.length + finish if finish && finish < 0
        finish = vecs.length - 1 if finish.nil?

        # Validate range
        if start < 0 || start >= vecs.length
          raise IndexError, "Start index #{start} out of bounds for embeddings size #{vecs.length}"
        end

        if finish < start || finish >= vecs.length
          raise IndexError, "End index #{finish} out of bounds for embeddings size #{vecs.length}"
        end

        vecs[start..finish]
      end

      # Combine with another EmbeddingResponse
      # @param other [Geminize::Models::EmbeddingResponse] Another embedding response to combine with
      # @return [Geminize::Models::EmbeddingResponse] A new combined response
      # @raise [Geminize::ValidationError] If the embeddings have different dimensions
      def combine(other)
        unless other.is_a?(Geminize::Models::EmbeddingResponse)
          raise Geminize::ValidationError.new(
            "Can only combine with another EmbeddingResponse",
            "INVALID_ARGUMENT"
          )
        end

        # Check dimension compatibility
        if dimensions != other.dimensions
          raise Geminize::ValidationError.new(
            "Cannot combine embeddings with different dimensions (#{dimensions} vs #{other.dimensions})",
            "INVALID_ARGUMENT"
          )
        end

        # Create a combined response hash
        combined_hash = {
          "embeddings" => [],
          "usageMetadata" => {
            "promptTokenCount" => 0,
            "totalTokenCount" => 0
          }
        }

        # Add embeddings from both responses
        self_vecs = embeddings
        other_vecs = other.embeddings

        # Prepare the embeddings format
        combined_embeddings = (self_vecs + other_vecs).map do |vec|
          {"values" => vec}
        end

        combined_hash["embeddings"] = combined_embeddings

        # Combine usage data if available
        if @usage
          combined_hash["usageMetadata"]["promptTokenCount"] += @usage["promptTokenCount"] || 0
          combined_hash["usageMetadata"]["totalTokenCount"] += @usage["totalTokenCount"] || 0
        end

        if other.usage
          combined_hash["usageMetadata"]["promptTokenCount"] += other.usage["promptTokenCount"] || 0
          combined_hash["usageMetadata"]["totalTokenCount"] += other.usage["totalTokenCount"] || 0
        end

        # Create a new response object
        self.class.from_hash(combined_hash)
      end

      # Save embeddings to a file
      # @param path [String] Path to save the file
      # @param format [Symbol] Format to save in (:json, :csv, :binary)
      # @param options [Hash] Additional options for saving
      # @option options [Boolean] :pretty Format JSON with indentation (for :json format)
      # @option options [Boolean] :include_header Include header with dimension indices (for :csv format)
      # @option options [Boolean] :include_metadata Include metadata in the saved file
      # @return [Boolean] True if successful
      # @raise [Geminize::ValidationError] If the format is invalid or file operations fail
      def save(path, format = :json, options = {})
        # Default options
        options = {
          pretty: false,
          include_header: true,
          include_metadata: true
        }.merge(options)

        begin
          File.open(path, "w") do |file|
            content = case format
            when :json
              data = {"embeddings" => embeddings}
              data["metadata"] = metadata if options[:include_metadata]

              options[:pretty] ? JSON.pretty_generate(data) : JSON.generate(data)
            when :csv
              to_csv(options[:include_header])
            when :binary
              raise Geminize::ValidationError.new(
                "Binary format not yet implemented",
                "INVALID_ARGUMENT"
              )
            else
              raise Geminize::ValidationError.new(
                "Unknown format: #{format}. Supported formats: :json, :csv",
                "INVALID_ARGUMENT"
              )
            end

            file.write(content)
          end

          true
        rescue => e
          raise Geminize::ValidationError.new(
            "Failed to save embeddings: #{e.message}",
            "IO_ERROR"
          )
        end
      end

      # Load embeddings from a file
      # @param path [String] Path to the file
      # @param format [Symbol, nil] Format of the file (:json, :csv, :binary)
      #   If nil, format will be inferred from file extension
      # @return [Geminize::Models::EmbeddingResponse] A new embedding response
      # @raise [Geminize::ValidationError] If the file format is invalid or file operations fail
      def self.load(path, format = nil)
        # Infer format from file extension if not specified
        if format.nil?
          ext = File.extname(path).downcase.delete(".")
          format = case ext
          when "json" then :json
          when "csv" then :csv
          when "bin" then :binary
          else
            raise Geminize::ValidationError.new(
              "Could not infer format from file extension: #{ext}",
              "INVALID_ARGUMENT"
            )
          end
        end

        begin
          content = File.read(path)

          case format
          when :json
            data = JSON.parse(content)

            if data["embeddings"]
              # Convert to API response format
              response_data = {
                "embeddings" => data["embeddings"].map { |vec| {"values" => vec} }
              }

              # Add usage metadata if available
              if data["metadata"] && data["metadata"]["total_tokens"]
                response_data["usageMetadata"] = {
                  "promptTokenCount" => data["metadata"]["prompt_tokens"] || 0,
                  "totalTokenCount" => data["metadata"]["total_tokens"] || 0
                }
              end

              from_hash(response_data)
            else
              # Assume it's already in the API response format
              from_hash(data)
            end
          when :csv
            lines = content.split("\n")

            # Skip header if it doesn't look like an embedding (has letters)
            has_header = lines[0].match?(/[a-zA-Z]/)

            # Parse vectors
            vectors = lines.map.with_index do |line, idx|
              next if idx == 0 && has_header
              line.split(",").map(&:to_f)
            end.compact

            # Create a response hash
            response_data = {
              "embeddings" => vectors.map { |vec| {"values" => vec} }
            }

            from_hash(response_data)
          when :binary
            raise Geminize::ValidationError.new(
              "Binary format not yet implemented",
              "INVALID_ARGUMENT"
            )
          else
            raise Geminize::ValidationError.new(
              "Unknown format: #{format}. Supported formats: :json, :csv",
              "INVALID_ARGUMENT"
            )
          end
        rescue JSON::ParserError => e
          raise Geminize::ValidationError.new(
            "Failed to parse JSON: #{e.message}",
            "INVALID_ARGUMENT"
          )
        rescue => e
          raise Geminize::ValidationError.new(
            "Failed to load embeddings: #{e.message}",
            "IO_ERROR"
          )
        end
      end

      # Perform simple clustering of embeddings
      # @param k [Integer] Number of clusters
      # @param max_iterations [Integer] Maximum number of iterations for clustering
      # @param metric [Symbol] Distance metric to use (:cosine or :euclidean)
      # @return [Hash] Hash with :clusters (array of indices) and :centroids (cluster centers)
      # @raise [Geminize::ValidationError] If clustering parameters are invalid
      # @note This is a basic implementation of k-means clustering for demonstration purposes
      def cluster(k, max_iterations = 100, metric = :cosine)
        vecs = embeddings

        if vecs.empty?
          raise Geminize::ValidationError.new(
            "Cannot cluster empty embeddings",
            "INVALID_ARGUMENT"
          )
        end

        if k <= 0 || k > vecs.length
          raise Geminize::ValidationError.new(
            "Number of clusters must be between 1 and #{vecs.length}, got: #{k}",
            "INVALID_ARGUMENT"
          )
        end

        # Normalize vectors for better clustering (especially important for cosine similarity)
        normalized_vecs = vecs.map { |v| VectorUtils.normalize(v) }

        # Initialize centroids using k-means++ algorithm
        centroids = kmeans_plus_plus_init(normalized_vecs, k, metric)

        # Initialize cluster assignments
        cluster_assignments = Array.new(normalized_vecs.length, -1)

        # Main K-means loop
        iterations = 0
        changes = true

        while changes && iterations < max_iterations
          changes = false

          # Assign points to clusters
          normalized_vecs.each_with_index do |vec, idx|
            best_distance = -Float::INFINITY
            best_cluster = -1

            centroids.each_with_index do |centroid, cluster_idx|
              # Calculate similarity (higher is better)
              similarity = case metric
              when :cosine
                VectorUtils.cosine_similarity(vec, centroid)
              when :euclidean
                # Convert to similarity (higher is more similar)
                1.0 / (1.0 + VectorUtils.euclidean_distance(vec, centroid))
              else
                raise Geminize::ValidationError.new(
                  "Unknown metric: #{metric}. Supported metrics: :cosine, :euclidean",
                  "INVALID_ARGUMENT"
                )
              end

              if similarity > best_distance
                best_distance = similarity
                best_cluster = cluster_idx
              end
            end

            # Update cluster assignment if it changed
            if cluster_assignments[idx] != best_cluster
              cluster_assignments[idx] = best_cluster
              changes = true
            end
          end

          # Update centroids
          new_centroids = Array.new(k) { [] }

          # Collect points for each cluster
          normalized_vecs.each_with_index do |vec, idx|
            cluster_idx = cluster_assignments[idx]
            new_centroids[cluster_idx] << vec if cluster_idx >= 0
          end

          # Calculate new centroids (average of points in each cluster)
          new_centroids.each_with_index do |cluster_points, idx|
            if cluster_points.empty?
              # If a cluster is empty, reinitialize with a point farthest from other centroids
              farthest_idx = find_farthest_point(normalized_vecs, centroids, cluster_assignments)
              centroids[idx] = normalized_vecs[farthest_idx].dup
            else
              # Otherwise take the average and normalize
              avg = VectorUtils.average_vectors(cluster_points)
              centroids[idx] = VectorUtils.normalize(avg)
            end
          end

          iterations += 1
        end

        # Organize results by cluster
        clusters = Array.new(k) { [] }
        cluster_assignments.each_with_index do |cluster_idx, idx|
          clusters[cluster_idx] << idx if cluster_idx >= 0
        end

        {
          clusters: clusters,
          centroids: centroids,
          iterations: iterations,
          metric: metric
        }
      end

      # Resize embeddings to a different dimension
      # @param new_dim [Integer] New dimension size
      # @param method [Symbol] Method to use for resizing (:truncate, :pad)
      # @param pad_value [Float] Value to use for padding when using :pad method
      # @return [Array<Array<Float>>] Resized embeddings
      # @raise [Geminize::ValidationError] If the resize parameters are invalid
      def resize(new_dim, method = :truncate, pad_value = 0.0)
        vecs = embeddings

        if vecs.empty?
          raise Geminize::ValidationError.new(
            "Cannot resize empty embeddings",
            "INVALID_ARGUMENT"
          )
        end

        if new_dim <= 0
          raise Geminize::ValidationError.new(
            "New dimension must be positive, got: #{new_dim}",
            "INVALID_ARGUMENT"
          )
        end

        unless [:truncate, :pad].include?(method)
          raise Geminize::ValidationError.new(
            "Unknown resize method: #{method}. Supported methods: :truncate, :pad",
            "INVALID_ARGUMENT"
          )
        end

        current_dim = dimensions

        case method
        when :truncate
          if new_dim > current_dim
            # If truncating but new_dim is larger, pad with zeros
            vecs.map do |vec|
              vec + Array.new(new_dim - current_dim, pad_value)
            end
          else
            # Otherwise truncate
            vecs.map { |vec| vec.take(new_dim) }
          end
        when :pad
          if new_dim > current_dim
            # Pad with specified value
            vecs.map do |vec|
              vec + Array.new(new_dim - current_dim, pad_value)
            end
          else
            # Truncate if new_dim is smaller
            vecs.map { |vec| vec.take(new_dim) }
          end
        end
      end

      # Apply a transformation to all embeddings
      # @yield [embedding, index] Block that transforms a single embedding
      # @yieldparam embedding [Array<Float>] The embedding vector
      # @yieldparam index [Integer] The index of the embedding
      # @yieldreturn [Array<Float>] The transformed embedding
      # @return [Array<Array<Float>>] Transformed embeddings
      # @raise [Geminize::ValidationError] If the transformation is invalid
      def map_embeddings
        return to_enum(:map_embeddings) unless block_given?

        vecs = embeddings
        result = []

        vecs.each_with_index do |vec, idx|
          transformed = yield(vec, idx)

          unless transformed.is_a?(Array)
            raise Geminize::ValidationError.new(
              "Transformation must return an array, got: #{transformed.class}",
              "INVALID_ARGUMENT"
            )
          end

          result << transformed
        end

        result
      end

      private

      # Validate the response data
      # @raise [Geminize::ValidationError] If the data doesn't contain valid embeddings
      def validate!
        # Ensure we have embedding data
        if !single? && !batch?
          raise Geminize::ValidationError.new("No embedding data found", "INVALID_RESPONSE")
        end

        # For single embeddings, ensure values is an array
        if single? && !@data["embedding"]["values"].is_a?(Array)
          raise Geminize::ValidationError.new("Embedding values must be an array", "INVALID_RESPONSE")
        end

        # For batch embeddings, validate each embedding
        if batch?
          if @data["embeddings"].empty?
            raise Geminize::ValidationError.new("Empty embeddings array", "INVALID_RESPONSE")
          end

          # Check that all embeddings have values as arrays
          @data["embeddings"].each_with_index do |emb, i|
            unless emb.is_a?(Hash) && emb.has_key?("values")
              raise Geminize::ValidationError.new(
                "Embedding at index #{i} must have 'values' key",
                "INVALID_RESPONSE"
              )
            end

            unless emb["values"].is_a?(Array)
              raise Geminize::ValidationError.new(
                "Embedding values at index #{i} must be an array",
                "INVALID_RESPONSE"
              )
            end
          end

          # Check that all embeddings have the same size
          sizes = @data["embeddings"].map { |emb| emb["values"].size }
          if sizes.uniq.size != 1
            raise Geminize::ValidationError.new("Inconsistent embedding sizes", "INVALID_RESPONSE")
          end
        end
      end

      # Parse the response data and extract relevant information
      def parse_response
        parse_usage
      end

      # Parse usage information from the response
      def parse_usage
        @usage = @data["usageMetadata"] if @data["usageMetadata"]
      end

      # Initialize centroids using k-means++ algorithm
      # @param vectors [Array<Array<Float>>] Input vectors
      # @param k [Integer] Number of clusters
      # @param metric [Symbol] Distance metric to use
      # @return [Array<Array<Float>>] Initial centroids
      def kmeans_plus_plus_init(vectors, k, metric)
        # Choose first centroid randomly
        centroids = [vectors[rand(vectors.length)].dup]

        # Choose remaining centroids
        (k - 1).times do
          # Calculate distances from each point to nearest centroid
          distances = vectors.map do |vec|
            # Find distance to closest centroid
            best_distance = -Float::INFINITY

            centroids.each do |centroid|
              similarity = case metric
              when :cosine
                VectorUtils.cosine_similarity(vec, centroid)
              when :euclidean
                1.0 / (1.0 + VectorUtils.euclidean_distance(vec, centroid))
              end

              best_distance = [best_distance, similarity].max
            end

            # Convert similarity to distance (lower is better for selection)
            1.0 - best_distance
          end

          # Calculate selection probabilities (higher distance = higher probability)
          sum_distances = distances.sum

          # Guard against division by zero
          if sum_distances.zero?
            # If all points are identical to centroids, choose randomly
            next_idx = rand(vectors.length)
          else
            # Choose next centroid with probability proportional to squared distance
            probabilities = distances.map { |d| (d / sum_distances) ** 2 }
            cumulative_prob = 0.0
            threshold = rand()
            next_idx = 0

            probabilities.each_with_index do |prob, idx|
              cumulative_prob += prob
              if cumulative_prob >= threshold
                next_idx = idx
                break
              end
            end
          end

          centroids << vectors[next_idx].dup
        end

        centroids
      end

      # Find the point farthest from existing centroids
      # @param vectors [Array<Array<Float>>] Input vectors
      # @param centroids [Array<Array<Float>>] Current centroids
      # @param assignments [Array<Integer>] Current cluster assignments
      # @return [Integer] Index of the farthest point
      def find_farthest_point(vectors, centroids, assignments)
        max_distance = -Float::INFINITY
        farthest_idx = 0

        vectors.each_with_index do |vec, idx|
          # Skip points already assigned as centroids
          next if centroids.any? { |c| c == vec }

          # Find minimum similarity to any centroid
          min_similarity = Float::INFINITY

          centroids.each do |centroid|
            similarity = VectorUtils.cosine_similarity(vec, centroid)
            min_similarity = [min_similarity, similarity].min
          end

          # Convert to distance
          distance = 1.0 - min_similarity

          if distance > max_distance
            max_distance = distance
            farthest_idx = idx
          end
        end

        farthest_idx
      end
    end
  end
end
