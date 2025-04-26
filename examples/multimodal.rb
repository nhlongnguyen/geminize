# frozen_string_literal: true

require "geminize"

# Configure with your API key
Geminize.configure do |config|
  # Use environment variable or set directly
  config.api_key = ENV["GEMINI_API_KEY"] || "your-api-key-here"

  # Specify the model to use (optional)
  config.default_model = "gemini-2.0-flash" # This model supports multimodal inputs
end

puts "============================================================"
puts "Example 1: Basic image and text input using a file path"
puts "============================================================"

begin
  # Generate content with an image from a file
  response = Geminize.generate_multimodal(
    "Describe this image in detail:",
    [{source_type: "file", data: "path/to/image.jpg"}]
  )

  puts "Response:"
  puts response.text
  puts "\nFinish reason: #{response.finish_reason}"
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure to update the image path to a real image on your system."
end

puts "\n============================================================"
puts "Example 2: Using image URL"
puts "============================================================"

begin
  # Generate content with an image from a URL
  response = Geminize.generate_multimodal(
    "What's in this image?",
    [{source_type: "url", data: "https://example.com/sample-image.jpg"}],
    nil, # Use default model
    temperature: 0.7
  )

  puts "Response with temperature=0.7:"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure to use a valid image URL."
end

puts "\n============================================================"
puts "Example 3: Multiple images comparison"
puts "============================================================"

begin
  # Generate content comparing multiple images
  response = Geminize.generate_multimodal(
    "Compare these two images and describe the differences:",
    [
      {source_type: "file", data: "path/to/image1.jpg"},
      {source_type: "file", data: "path/to/image2.jpg"}
    ],
    "gemini-1.5-pro-latest", # Explicitly specify model
    max_tokens: 500
  )

  puts "Response (max_tokens=500):"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure to update the image paths to real images on your system."
end

puts "\n============================================================"
puts "Example 4: Using raw image bytes with MIME type"
puts "============================================================"

begin
  # Read image directly into bytes
  image_bytes = File.binread("path/to/image.jpg")

  # Generate content with raw image bytes
  response = Geminize.generate_multimodal(
    "Analyze this image:",
    [{source_type: "bytes", data: image_bytes, mime_type: "image/jpeg"}]
  )

  puts "Response for raw bytes input:"
  puts response.text
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure to update the image path to a real image on your system."
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
    "gemini-1.5-pro-latest",
    temperature: 0.3,
    max_tokens: 800
  )

  # Add multiple images using different methods
  request.add_image_from_file("path/to/image1.jpg")
  request.add_image_from_url("https://example.com/image2.jpg")

  # Generate the response
  response = generator.generate(request)

  puts "Response using ContentRequest directly:"
  puts response.text
  puts "\nUsed #{response.usage.total_tokens} tokens total"
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure to update the paths to real images."
end
