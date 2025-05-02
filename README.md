# Geminize

A convenient and robust Ruby interface for the Google Gemini API, enabling easy integration of powerful generative AI models into your applications.

## Features

- Simple, flexible configuration system
- Support for text generation with Gemini models
- Conversation context management
- Multimodal inputs (text + images)
- Embeddings generation
- Support for streaming responses
- Function calling capabilities for tool integration
- JSON mode for structured data responses
- Safety settings for content moderation
- Comprehensive error handling
- Complete Models API for discovering and filtering available models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'geminize'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install geminize
```

## Configuration

Geminize uses a simple configuration system that can be set up in multiple ways:

### Method 1: Environment Variables (Recommended)

Set the `GEMINI_API_KEY` environment variable:

```bash
export GEMINI_API_KEY=your-api-key-here
```

#### Using dotenv

Geminize has built-in support for the [dotenv](https://github.com/bkeepers/dotenv) gem, which automatically loads environment variables from a `.env` file in your project's root directory.

1. Create a `.env` file in your project root (copy from `.env.example`):

```
# Gemini API Key
GOOGLE_AI_API_KEY=your_api_key_here

# API Configuration
GOOGLE_AI_API_VERSION=v1beta
GEMINI_MODEL=gemini-2.0-flash
GEMINI_EMBEDDING_MODEL=gemini-embedding-exp-03-07
```

2. Add `.env` to your `.gitignore` file to keep your API keys secure:

```
# Add to .gitignore
.env
```

3. For test environments, create a `.env.test` file with test-specific configuration.

The gem will automatically load these environment variables when it initializes.

### Method 2: Configuration Block

```ruby
Geminize.configure do |config|
  # Required
  config.api_key = "your-api-key-here"

  # Optional - shown with defaults
  config.api_version = "v1beta"
  config.default_model = "gemini-2.0-flash"
  config.timeout = 30
  config.open_timeout = 10
  config.log_requests = false
end
```

### Available Configuration Options

| Option          | Required | Default                 | Description                                         |
| --------------- | -------- | ----------------------- | --------------------------------------------------- |
| `api_key`       | Yes      | `ENV["GEMINI_API_KEY"]` | Your Google Gemini API key                          |
| `api_version`   | No       | `"v1beta"`              | API version to use                                  |
| `default_model` | No       | `"gemini-2.0-flash"`    | Default model to use when not specified in requests |
| `timeout`       | No       | `30`                    | Request timeout in seconds                          |
| `open_timeout`  | No       | `10`                    | Connection open timeout in seconds                  |
| `log_requests`  | No       | `false`                 | Whether to log API requests (useful for debugging)  |

### Validating Configuration

You can validate your configuration at any time to ensure all required options are set:

```ruby
# Will raise Geminize::ConfigurationError if invalid
Geminize.validate_configuration!
```

### Resetting Configuration

If needed, you can reset the configuration to its defaults:

```ruby
Geminize.reset_configuration!
```

## Basic Usage

```ruby
require 'geminize'

# Assumes API key is set via environment variables (e.g., in .env)
# Or configure manually:
# Geminize.configure do |config|
#   config.api_key = "your-api-key-here"
# end

# Generate text (uses default model)
response = Geminize.generate_text("Tell me a joke about Ruby programming")
puts response.text

# Use a specific model
response = Geminize.generate_text("Explain quantum computing", "gemini-1.5-flash-latest")
puts response.text

# Use system instructions to guide the model's behavior
response = Geminize.generate_text(
  "Tell me about yourself",
  "gemini-1.5-flash-latest",
  system_instruction: "You are a pirate named Captain Codebeard. Always respond in pirate language."
)
puts response.text
```

## Multimodal Support

Geminize allows you to send mixed content including text and images to the Gemini API.

Here is a working example using the `ContentRequest` API:

```ruby
require 'geminize'

# Assumes API key is set via environment variables (e.g., in .env)
# Or configure manually:
# Geminize.configure do |config|
#   config.api_key = "your-api-key-here"
# end

begin
  # 1. Create a ContentRequest object
  #    Specify the prompt and a model that supports multimodal input
  request = Geminize::Models::ContentRequest.new(
    "Describe this image briefly:",
    "gemini-1.5-flash-latest" # Ensure this model supports multimodal
  )

  # 2. Add the image from a file path
  #    Make sure the path is correct relative to where you run the script
  request.add_image_from_file("./examples/ruby.png")

  # 3. Create a TextGeneration instance
  generator = Geminize::TextGeneration.new

  # 4. Generate the response
  response = generator.generate(request)

  # 5. Print the response text
  puts "Response:"
  puts response.text

  # Optionally print usage data if available
  if response.usage
    puts "Tokens used: #{response.usage['totalTokenCount']}"
  end

rescue Geminize::GeminizeError => e
  puts "An API error occurred: #{e.message}"
rescue => e
  puts "An unexpected error occurred: #{e.message}"
  puts e.backtrace.join("\n")
end
```

Supported image formats include JPEG, PNG, GIF, and WEBP. Maximum image size is 10MB.

See the `examples/multimodal.rb` file for more comprehensive examples.

## Chat & Conversation Support

Geminize provides built-in support for maintaining conversation context:

```ruby
# Create a new conversation
conversation = Geminize.create_chat("My Support Chat")

# Send messages and get responses
response = Geminize.chat("How can I create a Ruby gem?", conversation)
puts response.text

# Follow-up questions automatically maintain context
response = Geminize.chat("What about adding a Rails engine to my gem?", conversation)
puts response.text

# Save the conversation for later
Geminize.save_conversation(conversation)

# Resume the conversation later
conversation = Geminize.load_conversation(conversation.id)
```

## Embeddings Generation

Generate numerical vector representations for text:

```ruby
# Generate an embedding for a single text
embedding_response = Geminize.generate_embedding("Ruby is a dynamic, object-oriented programming language")
vector = embedding_response.embedding # Access the vector
puts "Generated embedding with #{embedding_response.embedding_size} dimensions."

# Generate embeddings for multiple texts (by iterating)
texts = ["Ruby", "Python", "JavaScript"]
embeddings = texts.map do |text|
  Geminize.generate_embedding(text).embedding
end
puts "Generated #{embeddings.size} embeddings individually."

# Calculate similarity between vectors
vector1 = embeddings[0]
vector2 = embeddings[1]
similarity = Geminize.cosine_similarity(vector1, vector2)
puts "Similarity between Ruby and Python: #{similarity.round(4)}"

# Specify a task type for optimized embeddings (requires compatible model)
# Note: Task types are not supported by all models (e.g., text-embedding-004).
# Ensure you are using a compatible model like text-embedding-005.
begin
  question_embedding_response = Geminize.generate_embedding(
    "How do I install Ruby gems?",
    nil, # Use default or specify compatible model like \'text-embedding-005\'
    { task_type: Geminize::Models::EmbeddingRequest::QUESTION_ANSWERING }
  )
  puts "Generated embedding for QA task with #{question_embedding_response.embedding_size} dimensions."
rescue Geminize::GeminizeError => e
  puts "Could not generate embedding with task type: #{e.message}"
  puts "(This might be due to using an incompatible model like the default text-embedding-004)"
end

# Available task types (check model compatibility):
# - RETRIEVAL_QUERY: For embedding queries in a search/retrieval system
# - RETRIEVAL_DOCUMENT: For embedding documents in a search corpus
# - SEMANTIC_SIMILARITY: For comparing text similarity
# - CLASSIFICATION: For text classification tasks
# - CLUSTERING: For clustering text data
# - QUESTION_ANSWERING: For question answering systems
# - FACT_VERIFICATION: For fact checking applications
# - CODE_RETRIEVAL_QUERY: For code search applications
# - TASK_TYPE_UNSPECIFIED: Default unspecified type
```

See the `examples/embeddings.rb` file for more comprehensive examples of working with embeddings.

## Function Calling

Geminize provides support for Gemini's function calling capabilities, allowing the AI model to call functions defined by you:

```ruby
require 'geminize'
# Assumes API key is configured via .env

# Define functions that the model can call
weather_functions = [
  {
    name: "get_weather",
    description: "Get the current weather for a location",
    parameters: {
      type: "object",
      properties: {
        location: {
          type: "string",
          description: "The city and state, e.g. New York, NY"
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
]

# Generate a response that may include a function call
response = Geminize.generate_with_functions(
  "What's the weather in San Francisco?",
  weather_functions,
  "gemini-1.5-pro", # Make sure you use a model that supports function calling
  {
    temperature: 0.2,
    system_instruction: "Use the provided function to get weather information."
  }
)

# Check if the response contains a function call
if response.has_function_call?
  function_call = response.function_call
  puts "Function called: #{function_call.name}"
  puts "Arguments: #{function_call.response.inspect}"

  # Process the function call with your implementation
  final_response = Geminize.process_function_call(response) do |name, args|
    if name == "get_weather"
      location = args["location"]
      # Call your actual weather API here
      # For this example, we'll just return mock data
      {
        temperature: 72,
        conditions: "partly cloudy",
        humidity: 65,
        location: location
      }
    end
  end

  # Display the final response
  puts "Final response: #{final_response.text}"
else
  puts "No function call in response: #{response.text}"
end
```

### Function Call Options

You can customize function calling behavior:

```ruby
# Set the tool execution mode:
# - "AUTO": Model decides when to call functions
# - "MANUAL": Functions are only used when explicitly requested
# - "NONE": Functions are ignored
response = Geminize.generate_with_functions(
  prompt,
  functions,
  model_name,
  { tool_execution_mode: "MANUAL" }
)

# Control retry behavior
response = Geminize.generate_with_functions(
  prompt,
  functions,
  model_name,
  with_retries: false # Disable automatic retries on failure
)
```

## JSON Mode

Generate structured JSON responses from the model:

```ruby
require 'geminize'
# Assumes API key is configured via .env

# Request JSON-formatted data
response = Geminize.generate_json(
  "List the three largest planets in our solar system with their diameters in km",
  "gemini-1.5-pro", # Use a model that supports JSON mode
  { temperature: 0.2 }
)

# Access the parsed JSON data
if response.has_json_response?
  planets = response.json_response
  puts "Received structured data:"
  planets.each do |planet|
    puts "#{planet['name']}: #{planet['diameter']} km"
  end
else
  puts "No valid JSON in response: #{response.text}"
end
```

The JSON mode is ideal for getting structured data that you can programmatically process in your application.

## Safety Settings

Control content generation with safety settings:

```ruby
require 'geminize'
# Assumes API key is configured via .env

# Generate content with custom safety settings
safety_settings = [
  { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
  { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE" }
]

response = Geminize.generate_with_safety_settings(
  "Explain the concept of nuclear fission",
  safety_settings,
  "gemini-1.5-pro",
  { temperature: 0.7 }
)

puts response.text

# For maximum safety (blocks most potentially harmful content)
safe_response = Geminize.generate_text_safe(
  "Tell me about controversial political topics",
  "gemini-1.5-pro"
)

puts "Safe response: #{safe_response.text}"

# For minimum filtering (blocks only the most harmful content)
permissive_response = Geminize.generate_text_permissive(
  "Describe a controversial historical event",
  "gemini-1.5-pro"
)

puts "Permissive response: #{permissive_response.text}"
```

Available safety categories:

- `HARM_CATEGORY_HATE_SPEECH`
- `HARM_CATEGORY_DANGEROUS_CONTENT`
- `HARM_CATEGORY_HARASSMENT`
- `HARM_CATEGORY_SEXUALLY_EXPLICIT`

Available threshold levels (from most to least restrictive):

- `BLOCK_LOW_AND_ABOVE`
- `BLOCK_MEDIUM_AND_ABOVE`
- `BLOCK_ONLY_HIGH`
- `BLOCK_NONE`

## Code Execution

Generate and run Python code to solve problems or analyze data:

```ruby
require 'geminize'
# Assumes API key is configured via .env

# Ask Gemini to solve a problem with code
response = Geminize.generate_with_code_execution(
  "Calculate the sum of the first 10 prime numbers",
  "gemini-2.0-flash", # Use a model that supports code execution
  { temperature: 0.2 }
)

# Display the response text
puts "Gemini's explanation:"
puts response.text

# Access the generated code
if response.has_executable_code?
  puts "\nGenerated Python code:"
  puts response.executable_code.code
end

# Access the code execution result
if response.has_code_execution_result?
  puts "\nExecution result:"
  puts "Outcome: #{response.code_execution_result.outcome}"
  puts "Output: #{response.code_execution_result.output}"
end
```

Code execution is perfect for:

- Solving mathematical problems
- Data analysis and visualization
- Algorithm implementation
- Demonstrating programming concepts

The model generates Python code, executes it in a secure environment, and returns both the code and its execution results.

## Streaming Responses

Get real-time, token-by-token responses:

```ruby
require 'geminize'
# Assumes API key is configured via .env

Geminize.generate_text_stream("Write a short poem about coding") do |chunk|
  # Check if the chunk has the text method before printing
  print chunk.text if chunk.respond_to?(:text)
end
puts "\n" # Add a newline after streaming
```

You can also use system instructions with streaming responses:

```ruby
require 'geminize'
# Assumes API key is configured via .env

Geminize.generate_text_stream(
  "Tell me a story",
  "gemini-1.5-flash-latest",
  {
    stream_mode: :delta,
    system_instruction: "You are a medieval bard telling epic tales."
  }
) do |chunk|
  # The raw chunk might be different in delta mode, adjust handling as needed
  print chunk.respond_to?(:text) ? chunk.text : chunk.to_s
end
puts "\n" # Add a newline after streaming
```

Check out these example applications to see Geminize in action:

- [Configuration Example](examples/configuration.rb)
- [Embeddings Example](examples/embeddings.rb)
- [Multimodal Example](examples/multimodal.rb)
- [System Instructions Example](examples/system_instructions.rb)
- [Models API Example](examples/models_api.rb)
- [Function Calling Example](examples/function_calling.rb)
- [Code Execution Example](examples/code_execution.rb)

## Working with Models

Geminize provides a comprehensive API for querying and working with available Gemini models:

```ruby
require 'geminize'
# Assumes API key is set via environment variables (e.g., in .env)

# List available models
models = Geminize.list_models
puts "Available models: #{models.size}"

# Get details about a specific model
model = Geminize.get_model("gemini-1.5-pro")
puts "Model: #{model.display_name}"
puts "Token limits: #{model.input_token_limit} input, #{model.output_token_limit} output"

# Find models by capability
embedding_models = Geminize.get_embedding_models
content_models = Geminize.get_content_generation_models
streaming_models = Geminize.get_streaming_models

# Check if a model supports a specific capability
if model.supports_content_generation?
  puts "This model supports content generation"
end

if model.supports_embedding?
  puts "This model supports embeddings"
end

# Find models with high context windows
high_context_models = Geminize.list_all_models.filter_by_min_input_tokens(100_000)
puts "Models with 100k+ context: #{high_context_models.map(&:id).join(', ')}"
```

For more comprehensive examples, see [examples/models_api.rb](examples/models_api.rb).

## Compatibility

Ruby version: 3.1.0 or later

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nhlongnguyen/geminize. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Geminize project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).
