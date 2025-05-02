#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "geminize"
require "json"

# Configure the API key
Geminize.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"] # Make sure to set your API key in the environment
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

# First, generate a response with the function definition
response = Geminize.generate_with_functions(
  "What's the weather like in New York, Tokyo, and London?",
  [weather_function],
  nil,
  temperature: 0.2
)

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

    # Process the function result
    final_response = Geminize.process_function_call(response) do |name, arguments|
      get_weather(arguments["location"], arguments["unit"])
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

json_response = Geminize.generate_json(
  "Get the current temperature and weather conditions for New York, Tokyo, and London.",
  nil,
  system_instruction: "Return a JSON array with objects containing city, temperature in celsius, and conditions."
)

if json_response.has_json_response?
  puts "Structured JSON response:"
  puts JSON.pretty_generate(json_response.json_response)
else
  puts "Raw text response (not valid JSON):"
  puts json_response.text
end
