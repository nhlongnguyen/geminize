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
- Rails integration with controller concerns and view helpers

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

In Rails, you can use the dotenv gem and add it to your `.env` file:

```
GEMINI_API_KEY=your-api-key-here
```

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

# Configure with API key if not set via environment variables
Geminize.configure do |config|
  config.api_key = "your-api-key-here"
end

# Generate text
response = Geminize.generate_text("Tell me a joke about Ruby programming")
puts response.text

# Use a specific model
response = Geminize.generate_text("Explain quantum computing", "gemini-2.0-flash")
puts response.text
```

## Multimodal Support

Geminize allows you to send mixed content including text and images to the Gemini API:

```ruby
# Generate content with an image from a file
response = Geminize.generate_multimodal(
  "Describe this image in detail:",
  [{ source_type: 'file', data: 'path/to/image.jpg' }]
)
puts response.text

# Using an image URL
response = Geminize.generate_multimodal(
  "What's in this image?",
  [{ source_type: 'url', data: 'https://example.com/sample-image.jpg' }]
)
puts response.text

# Using multiple images
response = Geminize.generate_multimodal(
  "Compare these two images:",
  [
    { source_type: 'file', data: 'path/to/image1.jpg' },
    { source_type: 'file', data: 'path/to/image2.jpg' }
  ]
)
puts response.text
```

Alternatively, you can use the more flexible ContentRequest API:

```ruby
# Create a content request
request = Geminize::Models::ContentRequest.new(
  "Tell me about these images:",
  "gemini-2.0-flash"
)

# Add images using different methods
request.add_image_from_file('path/to/image1.jpg')
request.add_image_from_url('https://example.com/image2.jpg')

# Read image directly into bytes
image_bytes = File.binread('path/to/image3.jpg')
request.add_image_from_bytes(image_bytes, 'image/jpeg')

# Generate the response
generator = Geminize::TextGeneration.new
response = generator.generate(request)
puts response.text
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
embedding = Geminize.generate_embedding("Ruby is a dynamic, object-oriented programming language")
vector = embedding.values.first.value

# Generate embeddings for multiple texts
texts = ["Ruby", "Python", "JavaScript"]
embeddings = Geminize.generate_embedding(texts)

# Calculate similarity between vectors
vector1 = embeddings.values[0].value
vector2 = embeddings.values[1].value
similarity = Geminize.cosine_similarity(vector1, vector2)
puts "Similarity: #{similarity}"
```

## Streaming Responses

Get real-time, token-by-token responses:

```ruby
Geminize.generate_text_stream("Write a short poem about coding") do |chunk|
  print chunk.text
end
```

## Rails Integration

Geminize provides seamless integration with Rails applications.

### Setup

1. Add Geminize to your Gemfile:

```ruby
gem 'geminize'
```

2. Run the installer generator:

```bash
rails generate geminize:install
```

This creates a configuration initializer at `config/initializers/geminize.rb`

3. Add your API key to the initializer or via environment variables.

### Controller Integration

In your controllers, include the Geminize controller concern:

```ruby
class ChatController < ApplicationController
  # Add Geminize functionality to this controller
  geminize_controller

  def index
    # Optionally reset the conversation
    # reset_gemini_conversation("New chat session") if params[:reset]
  end

  def create
    # Send a message to Gemini and get the response
    @response = send_gemini_message(params[:message])

    respond_to do |format|
      format.html { redirect_to chat_path }
      format.turbo_stream
      format.json { render json: { message: @response.text } }
    end
  end
end
```

The concern provides the following methods:

- `current_gemini_conversation` - Access the current conversation (stored in session)
- `send_gemini_message(message, model_name=nil, params={})` - Send a message in the current conversation
- `generate_gemini_text(prompt, model_name=nil, params={})` - Generate text with Gemini
- `generate_gemini_multimodal(prompt, images, model_name=nil, params={})` - Generate text with images
- `generate_gemini_embedding(text, model_name=nil, params={})` - Generate embeddings
- `reset_gemini_conversation(title=nil)` - Start a new conversation

### View Integration

Include the Geminize view helpers in your application:

```ruby
# In app/helpers/application_helper.rb
module ApplicationHelper
  # Include Geminize view helpers
  geminize_helper
end
```

This provides the following helper methods:

- `render_gemini_conversation(conversation=nil, options={})` - Render the conversation as HTML
- `render_gemini_message(message, options={})` - Render a single message
- `gemini_chat_form(options={})` - Create a chat form
- `markdown_to_html(text, options={})` - Render Markdown as HTML (requires redcarpet gem)
- `highlight_code(html)` - Add syntax highlighting to code blocks (requires rouge gem)

Example view:

```erb
<%# app/views/chat/index.html.erb %>
<div class="chat-container">
  <h1>Chat with Gemini</h1>

  <div class="conversation">
    <%= render_gemini_conversation %>
  </div>

  <div class="chat-form">
    <%= gemini_chat_form(placeholder: "Ask me anything...", submit_text: "Send") %>
  </div>
</div>
```

## Example Applications

Check out these example applications to see Geminize in action:

- [Basic Chatbot](examples/chatbot.rb)
- [Image Analysis](examples/image_analysis.rb)
- [Semantic Search](examples/semantic_search.rb)
- [Rails Chat Application](examples/rails_chat) (coming soon)

## Compatibility

Ruby version: 3.1.0 or later
Rails version: 6.0 or later (for Rails integration)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nhlongnguyen/geminize. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Geminize project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).
