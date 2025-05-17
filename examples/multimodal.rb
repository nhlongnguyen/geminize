# frozen_string_literal: true

require "geminize"

# Configure with your API key
Geminize.configure do |config|
  # Use environment variable or set directly
  config.api_key = ENV["GEMINI_API_KEY"] || "your-api-key-here"

  # Specify the model to use (optional)
  # Use a model that supports multimodal input, like gemini-1.5-flash-latest
  config.default_model = "gemini-1.5-flash-latest"
end

puts "============================================================"
puts "Example 1: Basic image and text input using a file path"
puts "============================================================"

begin
  # Generate content with an image from a file
  response = Geminize.generate_text_multimodal(
    "Describe this image in detail:",
    [{source_type: "file", data: File.join(File.dirname(__FILE__), "ruby.png")}] # Use relative path from script
  )

  puts "Response:"
  puts response.text
  puts "\nFinish reason: #{response.finish_reason}"
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure the path './ruby.png' is correct relative to the project root."
end

puts "\n============================================================"
puts "Example 2: Using image URL"
puts "============================================================"

begin
  # Generate content with an image from a URL
  response = Geminize.generate_text_multimodal(
    "What's in this image?",
    [{source_type: "url", data: "https://miro.medium.com/v2/resize:fit:720/format:webp/1*zkA1cWgJDlMUxI5TRcIHdQ.jpeg"}], # Updated URL
    nil, # Use default model
    temperature: 0.7
  )

  puts "Response with temperature=0.7:"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure the URL is valid and accessible."
end

puts "\n============================================================"
puts "Example 3: Multiple images comparison"
puts "============================================================"

begin
  # Generate content comparing multiple images (using the same image twice here for simplicity)
  response = Geminize.generate_text_multimodal(
    "Compare these two images and describe the differences (they might be the same):",
    [
      {source_type: "file", data: File.join(File.dirname(__FILE__), "ruby.png")}, # Use relative path from script
      {source_type: "file", data: File.join(File.dirname(__FILE__), "ruby.png")}  # Use relative path from script
    ],
    "gemini-2.0-flash", # Explicitly specify model
    max_tokens: 500
  )

  puts "Response (max_tokens=500):"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure the path './ruby.png' is correct."
end

puts "\n============================================================"
puts "Example 4: Using raw image bytes with MIME type"
puts "============================================================"

begin
  # Read image directly into bytes
  image_bytes = File.binread(File.join(File.dirname(__FILE__), "ruby.png")) # Use relative path from script

  # Generate content with raw image bytes
  response = Geminize.generate_text_multimodal(
    "Analyze this image:",
    [{source_type: "bytes", data: image_bytes, mime_type: "image/png"}] # Updated MIME type
  )

  puts "Response for raw bytes input:"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure the path './ruby.png' is correct."
end

puts "\n============================================================"
puts "Example 5: Using ContentRequest directly for more control"
puts "============================================================"

begin
  # Create a generator
  generator = Geminize::TextGeneration.new

  # Create a content request
  request = Geminize::Models::ContentRequest.new(
    "Tell me about these images:",
    "gemini-2.0-flash",
    temperature: 0.3,
    max_tokens: 800
  )

  # Add multiple images using different methods
  request.add_image_from_file(File.join(File.dirname(__FILE__), "ruby.png")) # Use relative path from script
  request.add_image_from_url("https://miro.medium.com/v2/resize:fit:720/format:webp/1*zkA1cWgJDlMUxI5TRcIHdQ.jpeg") # Updated URL

  # Generate the response
  response = generator.generate(request)

  puts "Response using ContentRequest directly:"
  puts response.text

  # Check if usage data is available before accessing it
  if response.usage&.total_tokens
    puts "\nUsed #{response.usage.total_tokens} tokens total"
  else
    puts "\nUsage data not available in the response."
  end
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure paths and URLs are valid."
end
