# Technical Context

## Core Architecture

The Geminize gem follows a modular architecture with clear separation of concerns:

### Main Components

- **Client**: HTTP communication with the Gemini API
- **TextGeneration**: Text generation functionality
- **Embeddings**: Vector representation generation
- **Chat**: Conversation management
- **Models**: Data structures for requests/responses
- **Middleware**: Request processing pipeline
- **Configuration**: Environment and runtime configuration

## Key Technologies

- **Ruby 3.1+**: Modern Ruby language features
- **Faraday**: HTTP client library for API communication
- **Faraday-Retry**: Retry mechanism for transient failures
- **MIME-Types**: MIME type detection for multimodal content
- **JSON**: Data serialization and parsing

## Code Organization

```
lib/geminize/
  ├── client.rb                # HTTP client implementation
  ├── configuration.rb         # Configuration management
  ├── text_generation.rb       # Text generation functionality
  ├── chat.rb                  # Chat conversation handling
  ├── embeddings.rb            # Embedding vector generation
  ├── conversation_service.rb  # Conversation state management
  ├── request_builder.rb       # API request construction
  ├── vector_utils.rb          # Vector manipulation utilities
  ├── validators.rb            # Input validation functions
  ├── errors.rb                # Error class definitions
  ├── error_mapper.rb          # API error mapping
  ├── error_parser.rb          # Error response parsing
  ├── models/                  # Data models
  │   ├── content_request.rb   # Text generation request
  │   ├── content_response.rb  # API response data structure
  │   ├── embedding_request.rb # Embedding generation request
  │   ├── embedding_response.rb # Vector embedding response
  │   ├── conversation.rb      # Conversation state
  │   ├── message.rb           # Chat message structure
  │   └── ...
  └── middleware/              # Request processing middleware
      └── error_handler.rb     # Error handling middleware
```

## Dependencies

- **Runtime Dependencies**:

  - faraday (~> 2.0)
  - faraday-retry (~> 2.0)
  - mime-types (~> 3.5)

- **Development Dependencies**:
  - rspec (~> 3.0)
  - standard (~> 1.3)
  - vcr (~> 6.0)
  - webmock (~> 3.14)
  - dotenv (~> 2.8)

## Configuration Approaches

- Environment variables (GEMINI_API_KEY)
- Dotenv integration (.env file loading)
- Programmatic configuration via block syntax
- Default configuration with override options
