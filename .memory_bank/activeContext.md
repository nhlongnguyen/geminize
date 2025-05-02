# Active Context

## Current Focus Areas

### Core Functionality

- Text generation with Gemini models
- Chat conversation support
- Multimodal content handling (text + images)
- Embeddings generation
- Streaming responses

### Key Implementation Details

#### Text Generation

- Support for all Gemini models
- System instructions for guiding model behavior
- Generation parameters (temperature, top_k, top_p)
- Support for stop sequences

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

### Upcoming Features

- Support for newer Gemini models
- Advanced parameter tuning
- Additional vector operations
- Improved conversation persistence
