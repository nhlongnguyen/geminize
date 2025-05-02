#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"
require "json"

# Set to true to use mock responses instead of real API calls
# Useful for testing when API rate limits are exceeded
USE_MOCK = true

# Configure the API key
Geminize.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"] || "dummy-key-for-mock-mode" # Make sure to set your API key in the environment
  config.default_model = "gemini-1.5-pro-latest" # Use the latest model that supports function calling
end

# Define a weather function
def get_weather(location, unit = "celsius")
  puts "Getting weather for #{location} in #{unit}..."

  # In a real implementation, this would call a weather API
  # For this example, we'll return mock data
  case location.downcase
  when /new york/
    {temperature: (unit == "celsius") ? 22 : 72, conditions: "Sunny", humidity: 45}
  when /london/
    {temperature: (unit == "celsius") ? 15 : 59, conditions: "Rainy", humidity: 80}
  when /tokyo/
    {temperature: (unit == "celsius") ? 26 : 79, conditions: "Partly Cloudy", humidity: 65}
  else
    {temperature: (unit == "celsius") ? 20 : 68, conditions: "Unknown", humidity: 50}
  end
end

# Define a mock response class that mimics ContentResponse
class MockContentResponse
  attr_reader :text, :raw_response

  def initialize(text, has_function_call = false, function_name = nil, function_args = {})
    @text = text
    @has_function_call = has_function_call
    @function_name = function_name
    @function_args = function_args
  end

  def has_function_call?
    @has_function_call
  end

  def function_call
    return nil unless @has_function_call

    # Return a mock function response object
    mock_function = Struct.new(:name, :response).new(@function_name, @function_args)
    def mock_function.to_s
      "Function: #{name}(#{response.inspect})"
    end
    mock_function
  end

  def has_json_response?
    @text.start_with?("{", "[")
  end

  def json_response
    return nil unless has_json_response?
    JSON.parse(@text)
  end
end

# Define a function schema for get_weather
weather_function = {
  name: "get_weather",
  description: "Get the current weather in a location",
  parameters: {
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "The city and state or country, e.g., 'New York, NY' or 'London, UK'"
      },
      unit: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "The unit of temperature"
      }
    },
    required: ["location"]
  }
}

puts "Asking Gemini about the weather..."

response = if USE_MOCK
  # Create a mock response with a function call
  MockContentResponse.new(
    "I'll check the weather for you!",
    true,
    "get_weather",
    {"location" => "New York, NY"}
  )
else
  # First, generate a response with the function definition
  Geminize.generate_with_functions(
    "What's the weather like in New York, Tokyo, and London?",
    [weather_function],
    nil,
    {temperature: 0.2}
  )
end

# Check if the model wants to call a function
if response.has_function_call?
  function_call = response.function_call
  puts "Model wants to call function: #{function_call.name}"
  puts "With arguments: #{function_call.response.inspect}"

  # We'll need to handle multiple function calls for multiple cities
  # Let's process them one by one

  # Process the first function call
  function_name = function_call.name
  args = function_call.response

  if function_name == "get_weather"
    location = args["location"]
    unit = args["unit"] || "celsius"

    # Call our weather function
    weather_data = get_weather(location, unit)
    puts "Weather data for #{location}: #{weather_data.inspect}"

    final_response = if USE_MOCK
      # Create a mock final response
      MockContentResponse.new(
        "Based on the weather data provided:\n\n" \
        "In New York, it's currently 22°C (72°F) and Sunny with 45% humidity."
      )
    else
      # Process the function result
      Geminize.process_function_call(response) do |name, arguments|
        get_weather(arguments["location"], arguments["unit"])
      end
    end

    puts "\nFinal response from Gemini:"
    puts final_response.text
  end
else
  puts "Model did not request to call a function."
  puts "Response: #{response.text}"
end

# Example of using JSON mode
puts "\n\nUsing JSON mode to get weather data in structured format..."

json_response = if USE_MOCK
  # Create a mock JSON response
  MockContentResponse.new(
    '[{"city":"New York","temperature":22,"conditions":"Sunny"},
      {"city":"Tokyo","temperature":26,"conditions":"Partly Cloudy"},
      {"city":"London","temperature":15,"conditions":"Rainy"}]'
  )
else
  Geminize.generate_json(
    "Get the current temperature and weather conditions for New York, Tokyo, and London.",
    nil,
    {system_instruction: "Return a JSON array with objects containing city, temperature in celsius, and conditions."}
  )
end

if json_response.has_json_response?
  puts "Structured JSON response:"
  puts JSON.pretty_generate(json_response.json_response)
else
  puts "Raw text response (not valid JSON):"
  puts json_response.text
end
