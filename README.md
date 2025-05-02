# Geminize

A convenient and robust Ruby interface for the Google Gemini API, enabling easy integration of powerful generative AI models into your applications.

## Features

- Simple, flexible configuration system
- Support for text generation with Gemini models
- Conversation context management
- Multimodal inputs (text + images)
- Embeddings generation
- Support for streaming responses
- Comprehensive error handling

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
