# Tasks

## Current Tasks

### Documentation

- [ ] Review and improve YARD documentation
- [ ] Add more code examples
- [ ] Update README with latest features
- [ ] Create diagrams for architecture overview

### Feature Development

- [ ] Support for new Gemini models as they become available
- [ ] Add support for function calling capabilities
- [ ] Implement batch embedding generation
- [ ] Improve conversation persistence with adapter pattern for multiple storage options
- [ ] **Models API Integration**:
  - [x] Enhance `model_info.rb` to support full model metadata
  - [x] Update/create `Models::Model` class to match API response structure
  - [x] Implement `Models::ModelList` class for handling paginated results
  - [x] Add methods to `RequestBuilder` for models endpoints
  - [x] Add client methods for models endpoints
  - [x] Add convenience methods to main Geminize module
  - [x] Implement helper methods for model capability filtering
  - [x] Add comprehensive tests for models functionality
  - [x] Update documentation with models API examples

### Testing

- [ ] Expand test coverage
- [ ] Add integration tests for streaming
- [ ] Update VCR cassettes with latest API responses
- [ ] Add benchmarks for performance testing

### Improvements

- [ ] Optimize streaming buffer management
- [ ] Enhance error messages with more context
- [ ] Reduce memory footprint for large responses
- [ ] Add telemetry options for tracking API usage

### Bug Fixes

- [ ] Fix potential memory leak in streaming implementation
- [ ] Address timeout handling edge cases
- [ ] Improve error handling for network failures
- [ ] Fix MIME type detection for unusual file extensions

## Completed Tasks

### Core Implementation

- [x] Basic client implementation
- [x] Text generation support
- [x] Chat conversation support
- [x] Embeddings generation
- [x] Streaming response handling
- [x] Models API Integration

### Documentation

- [x] Initial README with examples
- [x] YARD documentation for public methods
- [x] Example scripts

### Testing

- [x] Basic test suite with RSpec
- [x] VCR setup for API mocking
- [x] Unit tests for core functionality

### Error Handling

- [x] Error class hierarchy
- [x] API error mapping
- [x] Input validation

## Backlog

### Features

- [ ] Rails integration improvements
- [ ] Async API support
- [ ] Advanced vector operations
- [ ] Batch processing for multiple requests
- [ ] CLI tool for quick testing
- [ ] Models API enhancements:
  - [ ] Caching model information to reduce API calls
  - [ ] Smart model selection based on input requirements
  - [ ] Model comparison utilities

### Optimizations

- [ ] Reduce API call overhead
- [ ] Implement request compression
- [ ] Add response caching
- [ ] Improve retry strategies
