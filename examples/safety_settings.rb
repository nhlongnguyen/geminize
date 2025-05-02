#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"

# Configure the API key
Geminize.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"] # Make sure to set your API key in the environment
  config.default_model = "gemini-1.5-pro-latest" # Use the latest model
end

# A prompt that might trigger safety filters
POTENTIALLY_SENSITIVE_PROMPT = "Describe a violent conflict scene from a movie"

puts "1. Generating with default safety settings:"
begin
  response = Geminize.generate_text(POTENTIALLY_SENSITIVE_PROMPT, nil, temperature: 0.2)
  puts "Default response:\n#{response.text}\n\n"
rescue Geminize::GeminizeError => e
  puts "Error with default settings: #{e.message}\n\n"
end

puts "2. Generating with maximum safety (blocking most potentially harmful content):"
begin
  response = Geminize.generate_text_safe(POTENTIALLY_SENSITIVE_PROMPT, nil, temperature: 0.2)
  puts "Maximum safety response:\n#{response.text}\n\n"
rescue Geminize::GeminizeError => e
  puts "Error with maximum safety: #{e.message}\n\n"
end

puts "3. Generating with minimum safety (blocking only high-risk content):"
begin
  response = Geminize.generate_text_permissive(POTENTIALLY_SENSITIVE_PROMPT, nil, temperature: 0.2)
  puts "Minimum safety response:\n#{response.text}\n\n"
rescue Geminize::GeminizeError => e
  puts "Error with minimum safety: #{e.message}\n\n"
end

puts "4. Generating with custom safety settings:"
begin
  # Custom safety settings:
  # - Block medium and above for dangerous content
  # - Block low and above for hate speech
  # - Block only high for sexually explicit content
  # - No blocks for harassment
  custom_safety_settings = [
    { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
    { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE" },
    { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
    { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE" }
  ]

  response = Geminize.generate_with_safety_settings(
    POTENTIALLY_SENSITIVE_PROMPT,
    custom_safety_settings,
    nil,
    temperature: 0.2
  )
  puts "Custom safety response:\n#{response.text}\n\n"
rescue Geminize::GeminizeError => e
  puts "Error with custom safety: #{e.message}\n\n"
end

# Demonstrate direct usage of safety settings in a ContentRequest
puts "5. Using safety settings directly in a ContentRequest:"
begin
  generator = Geminize::TextGeneration.new
  content_request = Geminize::Models::ContentRequest.new(
    POTENTIALLY_SENSITIVE_PROMPT,
    nil,
    temperature: 0.2
  )

  # Add specific safety settings
  content_request.add_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_MEDIUM_AND_ABOVE")

  response = generator.generate(content_request)
  puts "ContentRequest safety response:\n#{response.text}\n\n"
rescue Geminize::GeminizeError => e
  puts "Error with ContentRequest safety: #{e.message}\n\n"
end
