#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"

# Configure the API key
Geminize.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"] # Make sure to set your API key in the environment
  config.default_model = "gemini-2.0-flash" # Use a model that supports code execution
end

puts "==========================================="
puts "=    GEMINIZE CODE EXECUTION EXAMPLES     ="
puts "==========================================="

puts "\n=== BASIC CODE EXECUTION EXAMPLE ==="
puts "Asking Gemini to calculate the sum of the first 50 prime numbers..."

begin
  # Generate a response with code execution enabled
  response = Geminize.generate_with_code_execution(
    "What is the sum of the first 50 prime numbers? Generate and run code for the calculation, and make sure you get all 50.",
    nil,
    {temperature: 0.2}
  )

  # Display the generated text
  puts "\nGemini's response:"
  puts response.text

  # Display the executable code if present
  if response.has_executable_code?
    puts "\nGenerated code:"
    puts "```#{response.executable_code.language.downcase}"
    puts response.executable_code.code
    puts "```"
  end

  # Display the code execution result if present
  if response.has_code_execution_result?
    puts "\nCode execution result:"
    puts "Outcome: #{response.code_execution_result.outcome}"
    puts "Output: #{response.code_execution_result.output}"
  end
rescue => e
  puts "Error during code execution: #{e.message}"
end

puts "\n\n=== PRACTICAL CODE EXECUTION EXAMPLE ==="
puts "Asking Gemini to analyze some text data..."

begin
  # Generate a response with code execution for data analysis
  response = Geminize.generate_with_code_execution(
    "I have a list of temperatures: 32, 25, 30, 22, 28, 27, 35, 31, 29, 26. " \
    "Please write code to calculate the mean, median, and standard deviation. " \
    "Also, create a simple histogram visualization using matplotlib.",
    nil,
    {temperature: 0.2}
  )

  # Display the generated text
  puts "\nGemini's response:"
  puts response.text

  # Display the executable code if present
  if response.has_executable_code?
    puts "\nGenerated code:"
    puts "```#{response.executable_code.language.downcase}"
    puts response.executable_code.code
    puts "```"
  end

  # Display the code execution result if present
  if response.has_code_execution_result?
    puts "\nCode execution result:"
    puts "Outcome: #{response.code_execution_result.outcome}"
    puts "Output: #{response.code_execution_result.output}"
  end
rescue => e
  puts "Error during code execution: #{e.message}"
end

puts "\n\n=== ITERATIVE PROBLEM SOLVING EXAMPLE ==="
puts "Asking Gemini to solve a complex problem using code execution..."

begin
  # Generate a response for a more complex problem
  response = Geminize.generate_with_code_execution(
    "Write a Python function to find the nth Fibonacci number where n is a positive integer. " \
    "Then use this function to calculate the 50th Fibonacci number. " \
    "Implement it efficiently using memoization to avoid redundant calculations.",
    nil,
    {temperature: 0.2}
  )

  # Display the generated text
  puts "\nGemini's response:"
  puts response.text

  # Display the executable code if present
  if response.has_executable_code?
    puts "\nGenerated code:"
    puts "```#{response.executable_code.language.downcase}"
    puts response.executable_code.code
    puts "```"
  end

  # Display the code execution result if present
  if response.has_code_execution_result?
    puts "\nCode execution result:"
    puts "Outcome: #{response.code_execution_result.outcome}"
    puts "Output: #{response.code_execution_result.output}"
  end
rescue => e
  puts "Error during code execution: #{e.message}"
  puts "\nNOTE: If you hit a quota limit, try:"
  puts "1. Using a paid API key with higher quotas"
  puts "2. Reducing the number of examples you run"
  puts "3. Adding delays between API calls"
end

puts "\n==========================================="
puts "=            END OF EXAMPLES              ="
puts "==========================================="
