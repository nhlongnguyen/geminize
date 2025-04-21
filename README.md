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
- Rails integration (coming soon)

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
  config.default_model = "gemini-1.5-pro-latest"
  config.timeout = 30
  config.open_timeout = 10
  config.log_requests = false
end
```

## Basic Usage

```ruby
require 'geminize'

# Configure with API key if not set via environment variables
Geminize.configure do |config|
  config.api_key = "your-api-key-here"
end

# Initialize a client
client = Geminize::Client.new

# Generate text
response = client.generate_text("Tell me a joke about Ruby programming")
puts response.text

# Use a specific model
response = client.generate_text("Explain quantum computing", model: "gemini-1.5-flash-latest")
puts response.text
```

See the `examples` directory for more usage examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nhlongnguyen/geminize. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Geminize project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nhlongnguyen/geminize/blob/main/CODE_OF_CONDUCT.md).
