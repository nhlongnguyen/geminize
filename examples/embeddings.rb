#!/usr/bin/env ruby
# frozen_string_literal: true

require "geminize"

# This example demonstrates how to use the Geminize embedding API
# to generate vector embeddings for text

# Configure with your API key
Geminize.configure do |config|
  # Use environment variable or set directly
  config.api_key = ENV["GEMINI_API_KEY"] || "your-api-key-here"

  # Optional: Set a default embedding model
  config.default_embedding_model = "text-embedding-004"
end

puts "============================================================"
puts "Example 1: Generate embedding for a single text"
puts "============================================================"

begin
  # Generate embedding for a single text
  text = "What is the meaning of life?"
  response = Geminize.generate_embedding(text)

  puts "Generated embedding with #{response.embedding_size} dimensions"
  puts "First 5 values: #{response.embedding.take(5).inspect}"
  puts "Total tokens: #{response.total_tokens}"
rescue => e
  puts "Error: #{e.message}"
end

puts "\n============================================================"
puts "Example 2: Generate embeddings for multiple texts"
puts "============================================================"

begin
  # Generate embeddings for multiple texts in a single API call
  texts = [
    "What is the meaning of life?",
    "How much wood would a woodchuck chuck?",
    "How does the brain work?"
  ]

  response = Geminize.generate_embedding(texts)

  puts "Generated #{response.batch_size} embeddings, each with #{response.embedding_size} dimensions"

  # Access individual embeddings
  texts.each_with_index do |text, i|
    puts "\nText: \"#{text}\""
    puts "First 5 values: #{response.embedding_at(i).take(5).inspect}"
  end

  puts "\nTotal tokens: #{response.total_tokens}"
rescue => e
  puts "Error: #{e.message}"
end

puts "\n============================================================"
puts "Example 3: Generate embeddings with task type and dimensions"
puts "============================================================"

begin
  text = "This is a sample text for similarity comparison"

  # Generate with specific task type for better performance
  response = Geminize.generate_embedding(
    text,
    "text-embedding-004", # You can specify a model explicitly
    task_type: "SEMANTIC_SIMILARITY", # Optimize for similarity comparisons
    dimensions: 768 # Request specific dimensions (if supported by model)
  )

  puts "Generated embedding optimized for SEMANTIC_SIMILARITY"
  puts "Dimensions: #{response.embedding_size}"
  puts "First 5 values: #{response.embedding.take(5).inspect}"
rescue => e
  puts "Error: #{e.message}"
end

puts "\n============================================================"
puts "Example 4: Batch processing for large arrays"
puts "============================================================"

begin
  # Create a larger array of texts
  many_texts = Array.new(120) { |i| "This is sample text number #{i}" }

  # Generate embeddings with automatic batch processing
  response = Geminize.generate_embedding(
    many_texts,
    nil, # Use default model
    batch_size: 40 # Process in batches of 40 texts each
  )

  puts "Generated embeddings for #{response.batch_size} texts"
  puts "First text embedding dimensions: #{response.embedding_size}"
  puts "Total tokens processed: #{response.total_tokens}"
rescue => e
  puts "Error: #{e.message}"
end

puts "\n============================================================"
puts "Example 5: Vector operations with embeddings"
puts "============================================================"

begin
  # Generate embeddings for two related texts
  text1 = "Artificial intelligence is changing the world"
  text2 = "Machine learning technologies are transforming industries"

  response1 = Geminize.generate_embedding(text1)
  response2 = Geminize.generate_embedding(text2)

  # Calculate cosine similarity
  similarity = Geminize.cosine_similarity(response1.embedding, response2.embedding)

  puts "Similarity between related texts: #{similarity.round(4)}"

  # Compare with unrelated text
  text3 = "The quick brown fox jumps over the lazy dog"
  response3 = Geminize.generate_embedding(text3)

  unrelated_similarity = Geminize.cosine_similarity(response1.embedding, response3.embedding)

  puts "Similarity with unrelated text: #{unrelated_similarity.round(4)}"

  # Calculate average embedding
  avg_embedding = Geminize.average_vectors([response1.embedding, response2.embedding])
  puts "Created average embedding vector with #{avg_embedding.size} dimensions"
rescue => e
  puts "Error: #{e.message}"
end
