#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"

# This example demonstrates how to use system instructions with Geminize
# System instructions allow you to guide the model's behavior and provide context
# that influences all responses.

# Configure with your API key
Geminize.configure do |config|
  config.api_key = ENV["GOOGLE_AI_API_KEY"] || ENV["GEMINI_API_KEY"]
end

puts "EXAMPLE 1: Basic system instruction with generate_text"
puts "====================================================="

response = Geminize.generate_text(
  "Tell me about yourself",
  "gemini-2.0-flash",
  system_instruction: "You are a cat named Whiskers. Always speak like a cat."
)

puts "Response:\n#{response.text}"
puts "\n"

puts "EXAMPLE 2: Using system instructions with ContentRequest directly"
puts "=============================================================="

request = Geminize::Models::ContentRequest.new(
  "Explain quantum computing",
  "gemini-2.0-flash",
  temperature: 0.7,
  max_tokens: 150
)

request.system_instruction = "You are a science teacher speaking to a 10-year-old. Use simple language."

generator = Geminize::TextGeneration.new
response = generator.generate(request)

puts "Response:\n#{response.text}"
puts "\n"

puts "EXAMPLE 3: System instructions with conversation"
puts "=============================================="

# Start a new conversation with a system instruction
conversation = Geminize.create_chat("Role-playing Chat")

# The system instruction guides the entire conversation
conversation.system_instruction = "You are a ship's computer named HAL on a spaceship. Respond in a calm, slightly robotic manner with space-related terminology."

# First message
response = Geminize.chat("Hello there, who are you?", conversation)
puts "Response 1:\n#{response.text}\n"

# Follow-up
response = Geminize.chat("What can you help me with?", conversation)
puts "Response 2:\n#{response.text}\n"

puts "EXAMPLE 4: Streaming with system instructions"
puts "==========================================="

puts "Response:"
Geminize.generate_text_stream(
  "Write a short introduction to a mystery novel",
  "gemini-2.0-flash",
  {
    stream_mode: :delta,
    max_tokens: 150,
    system_instruction: "You are a noir detective writer from the 1940s."
  }
) do |chunk|
  print chunk unless chunk.is_a?(Hash)
end

puts "\n\nEXAMPLE 5: Different personas with system instructions"
puts "====================================================="

personas = [
  "You are a Victorian-era poet. Use flowery, elaborate language.",
  "You are a modern tech startup founder. Use buzzwords and be enthusiastic.",
  "You are a grumpy old professor. Be critical and reference obscure theories."
]

prompt = "What do you think about social media?"

personas.each_with_index do |persona, i|
  puts "\nPersona #{i + 1}:"
  puts "-" * 50
  response = Geminize.generate_text(
    prompt,
    "gemini-2.0-flash",
    system_instruction: persona,
    max_tokens: 150
  )
  puts response.text
  puts "-" * 50
end
