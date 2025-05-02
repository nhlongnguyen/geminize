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

# Define a weather function that can handle a location and unit
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

# Enhanced weather function that can handle a batch of locations
def get_weather_batch(locations, unit = "celsius")
  if locations.is_a?(Array)
    results = {}
    locations.each do |location|
      results[location] = get_weather(location, unit)
    end
    results
  else
    {locations => get_weather(locations, unit)}
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

# Define a batch weather function schema that can handle multiple locations
batch_weather_function = {
  name: "get_weather_batch",
  description: "Get the current weather for multiple locations at once",
  parameters: {
    type: "object",
    properties: {
      locations: {
        type: "array",
        items: {
          type: "string"
        },
        description: "List of cities, e.g., ['New York, NY', 'London, UK', 'Tokyo, Japan']"
      },
      unit: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "The unit of temperature"
      }
    },
    required: ["locations"]
  }
}

puts "==========================================="
puts "= GEMINIZE FUNCTION CALLING & JSON EXAMPLES ="
puts "==========================================="

puts "\n=== FUNCTION CALLING EXAMPLE ==="
puts "Asking Gemini about the weather in New York..."

begin
  # Generate a response with the function definition
  response = Geminize.generate_with_functions(
    "What's the weather like in New York?",
    [weather_function],
    nil,
    {temperature: 0.2}
  )

  # Check if the model wants to call a function
  if response.has_function_call?
    function_call = response.function_call
    puts "Model wants to call function: #{function_call.name}"
    puts "With arguments: #{function_call.response.inspect}"

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
    else
      puts "Unexpected function call: #{function_name}"
    end
  else
    puts "Model did not request to call a function."
    puts "Response: #{response.text}"
  end
rescue => e
  puts "Error during function calling: #{e.message}"
end

# Example of using JSON mode
puts "\n\n=== JSON MODE EXAMPLE ==="
puts "Using JSON mode to get weather data in structured format..."

begin
  json_response = Geminize.generate_json(
    "Get the current temperature and weather conditions for New York.",
    nil,
    {
      system_instruction: "Return a JSON object with temperature in celsius and conditions."
    }
  )

  if json_response.has_json_response?
    puts "Structured JSON response:"
    puts JSON.pretty_generate(json_response.json_response)
  else
    puts "Raw text response (not valid JSON):"
    puts json_response.text
  end
rescue => e
  puts "Error during JSON mode: #{e.message}"
end

puts "\n\n=== BATCH FUNCTION CALL EXAMPLE ==="
puts "Using batch function to efficiently get weather for multiple cities at once..."

begin
  # Use a batch function to get all cities at once (more efficient)
  response = Geminize.generate_with_functions(
    "I need weather information for New York, Tokyo, and London. Please get all this information in a single function call.",
    [batch_weather_function],
    nil,
    {temperature: 0.2}
  )

  # Check if the model wants to call the batch function
  if response.has_function_call?
    function_call = response.function_call
    puts "Model wants to call function: #{function_call.name}"
    puts "With arguments: #{function_call.response.inspect}"

    function_name = function_call.name
    args = function_call.response

    if function_name == "get_weather_batch"
      locations = args["locations"]
      unit = args["unit"] || "celsius"

      # Get weather for all locations at once
      weather_data = get_weather_batch(locations, unit)
      puts "Weather data for multiple locations: #{weather_data.inspect}"

      # Process the function result with a single API call
      final_response = Geminize.process_function_call(response) do |name, arguments|
        get_weather_batch(arguments["locations"], arguments["unit"])
      end

      puts "\nFinal response from Gemini:"
      puts final_response.text
    else
      puts "Unexpected function call: #{function_name}"
    end
  else
    puts "Model did not request to call a function."
    puts "Response: #{response.text}"
  end
rescue => e
  puts "Error during batch function calling: #{e.message}"
  puts "\nNOTE: If you hit a quota limit, try:"
  puts "1. Using a paid API key with higher quotas"
  puts "2. Reducing the number of examples you run"
  puts "3. Adding delays between API calls"
end

puts "\n==========================================="
puts "= END OF EXAMPLES ="
puts "==========================================="
