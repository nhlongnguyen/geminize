# Active Context

## Current Focus Areas

### Core Functionality

- Text generation with Gemini models
- Chat conversation support
- Multimodal content handling (text + images)
- Embeddings generation
- Streaming responses
- Function calling capabilities
- JSON mode for structured responses
- Safety settings for content moderation

### Key Implementation Details

#### Text Generation

- Support for all Gemini models
- System instructions for guiding model behavior
- Generation parameters (temperature, top_k, top_p)
- Support for stop sequences
- Safety settings for content moderation

#### Function Calling

- Tool integration with Gemini API
- Function declaration and response models
- Support for multiple function definitions
- Tool execution modes (AUTO, MANUAL, NONE)
- Function result processing
- String-based function call detection

#### JSON Mode

- Structured data response handling
- Automatic JSON parsing
- JSON schema integration
- Response validation

#### Multimodal Support

- Image handling from multiple sources (files, URLs, bytes)
- MIME type detection and validation
- Size limits enforcement
- Support for JPEG, PNG, GIF, WEBP formats

#### Chat & Conversations

- Conversation state management
- Message history tracking
- Context preservation
- System instructions for chat

#### Embeddings

- Vector generation for semantic text analysis
- Vector similarity operations
- Task type optimization
- Normalization utilities

#### Streaming

- Multiple streaming modes (raw, incremental, delta)
- Cancellation support
- Efficient buffer management
- Error handling for interrupted streams

### API and HTTP Communication

- Robust HTTP client implementation
- Retry mechanisms for transient errors
- Timeout handling
- Response parsing and validation

### Error Handling Strategy

- Comprehensive error class hierarchy
- Detailed error messages
- API error translation
- Validation prior to API calls

## Active Development Areas

### Current Improvements

- Enhanced multimodal support
- Streaming response optimizations
- Comprehensive documentation
- Error handling refinements
- Models API integration
- Function calling support

### Upcoming Features

- Code execution support
- Additional content types (audio, PDF)
- Caching support
- Advanced parameter tuning
- Additional vector operations
- Improved conversation persistence
