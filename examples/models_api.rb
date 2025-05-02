#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"
require "pp"

# Configure the library with your API key
Geminize.configure do |config|
  # Load API key from .env file or environment variables
  config.api_key = ENV["GEMINI_API_KEY"]
  # Use the latest API version
  config.api_version = "v1beta"
end

# Helper method to display model information
def display_model(model)
  puts "========================"
  puts "Model: #{model.display_name} (#{model.name})"
  puts "Base Model ID: #{model.base_model_id}"
  puts "Version: #{model.version}"
  puts "Description: #{model.description}"
  puts "Input Token Limit: #{model.input_token_limit}"
  puts "Output Token Limit: #{model.output_token_limit}"
  puts "Temperature: #{model.temperature}"
  puts "Max Temperature: #{model.max_temperature}"
  puts "Top P: #{model.top_p}"
  puts "Top K: #{model.top_k}"
  puts "Supported Methods: #{model.supported_generation_methods.join(", ")}"
  puts "Capabilities:"
  puts "  - Content Generation: #{model.supports_content_generation?}"
  puts "  - Chat: #{model.supports_message_generation?}"
  puts "  - Embedding: #{model.supports_embedding?}"
  puts "  - Streaming: #{model.supports_streaming?}"
  puts "========================\n\n"
end

puts "=== MODELS API EXAMPLES ==="

# Example 1: List models (first page)
puts "\n=== Example 1: List first page of models ==="
begin
  model_list = Geminize.list_models(page_size: 5)
  puts "Found #{model_list.size} models on first page"
  puts "Has more pages: #{model_list.has_more_pages?}"
  puts "Next page token: #{model_list.next_page_token}"
  puts "\nFirst model details:"
  display_model(model_list.first) if model_list.first
rescue => e
  puts "Error listing models: #{e.message}"
end

# Example 2: Get detailed info for a specific model
puts "\n=== Example 2: Get specific model info ==="
begin
  model = Geminize.get_model("gemini-1.5-flash")
  puts "Retrieved model details:"
  display_model(model)
rescue => e
  puts "Error getting model: #{e.message}"
end

# Example 3: Get all models (handling pagination)
puts "\n=== Example 3: Get all models (handling pagination) ==="
begin
  all_models = Geminize.list_all_models
  puts "Retrieved #{all_models.size} models in total"
rescue => e
  puts "Error listing all models: #{e.message}"
end

# Example 4: Filter models by capability
puts "\n=== Example 4: Filter models by capability ==="
begin
  # Get models that support embedding
  embedding_models = Geminize.get_embedding_models
  puts "Found #{embedding_models.size} models that support embeddings"

  # Get models that support content generation
  content_models = Geminize.get_content_generation_models
  puts "Found #{content_models.size} models that support content generation"

  # Get models that support chat
  chat_models = Geminize.get_chat_models
  puts "Found #{chat_models.size} models that support chat"

  # Get models that support streaming
  streaming_models = Geminize.get_streaming_models
  puts "Found #{streaming_models.size} models that support streaming"
rescue => e
  puts "Error filtering models: #{e.message}"
end

# Example 5: Filter models by specific method
puts "\n=== Example 5: Filter models by specific method ==="
begin
  method_models = Geminize.get_models_by_method("generateContent")
  puts "Found #{method_models.size} models that support generateContent"

  # Display a specific model from the filtered list
  if method_models.size > 0
    puts "\nExample of a model supporting generateContent:"
    display_model(method_models.first)
  end
rescue => e
  puts "Error filtering by method: #{e.message}"
end

# Example 6: Model comparison
puts "\n=== Example 6: Compare token limits ==="
begin
  all_models = Geminize.list_all_models

  # Filter to models with higher token limits
  high_capacity_models = all_models.filter_by_min_input_tokens(100_000)

  puts "Models with 100k+ input token limits:"
  high_capacity_models.each do |model|
    puts "  - #{model.display_name}: #{model.input_token_limit} input tokens"
  end
rescue => e
  puts "Error comparing models: #{e.message}"
end

puts "\n=== Examples Complete ==="
