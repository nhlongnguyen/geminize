# Tasks

## Current Tasks

### Documentation

- [ ] Review and improve YARD documentation
- [ ] Add more code examples
- [x] Update README with latest features
- [ ] Create diagrams for architecture overview

### Feature Development

- [ ] Support for new Gemini models as they become available
- [ ] Implement Gemini API missing features:
  - [x] **Function Calling Support**
    - [x] Create model classes for function calling structures
    - [x] Update ContentRequest to support tools and functions
    - [x] Update request builder and response handling
    - [x] Add module-level convenience methods
    - [x] Add comprehensive VCR tests for function calling
  - [x] **JSON Mode Support**
    - [x] Add MIME type support for JSON responses
    - [x] Implement helper methods for JSON generation
    - [x] Add validation for JSON response structures
    - [x] Add tests for JSON mode functionality
  - [x] **Safety Settings**
    - [x] Create SafetySetting model
    - [x] Add safety configuration to requests
    - [x] Implement module-level safety methods
    - [x] Add tests for safety settings
  - [x] **Code Execution Support**
    - [x] Create code execution model classes
    - [x] Implement code execution tools in requests
    - [x] Update response handling for code execution
    - [x] Add module-level code execution methods
    - [x] Create example script for code execution
  - [ ] **Additional Content Types**
    - [ ] Audio content support
    - [ ] Document/PDF content support
    - [ ] Video content support
  - [ ] **Caching Support**
    - [ ] Add caching to content requests
    - [ ] Implement cached content handling
    - [ ] Add module-level caching methods
- [x] Add support for function calling capabilities
- [ ] Implement batch embedding generation
- [ ] Improve conversation persistence with adapter pattern for multiple storage options

### Testing

- [ ] Expand test coverage
- [ ] Add integration tests for streaming
- [x] Update VCR cassettes with latest API responses
- [ ] Add benchmarks for performance testing
- [x] Create test fixtures for new Gemini API features
- [x] Add VCR cassettes for function calling responses

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
  - [x] Enhance `model_info.rb` to support full model metadata
  - [x] Update/create `Models::Model` class to match API response structure
  - [x] Implement `Models::ModelList` class for handling paginated results
  - [x] Add methods to `RequestBuilder` for models endpoints
  - [x] Add client methods for models endpoints
  - [x] Add convenience methods to main Geminize module
  - [x] Implement helper methods for model capability filtering
  - [x] Add comprehensive tests for models functionality
  - [x] Update documentation with models API examples
- [x] Function Calling Support
  - [x] Create function declaration, tool, and response models
  - [x] Implement request and response extensions
  - [x] Add module-level methods for function calling
  - [x] Add VCR tests for real API interactions
- [x] JSON Mode Support
  - [x] Add MIME type support and JSON response parsing
  - [x] Add structured data generation features
- [x] Safety Settings Support
  - [x] Implement safety categories and thresholds
  - [x] Add safety-focused generation methods

### Documentation

- [x] Initial README with examples
- [x] YARD documentation for public methods
- [x] Example scripts
- [x] Update README with function calling, JSON mode, and safety settings

### Testing

- [x] Basic test suite with RSpec
- [x] VCR setup for API mocking
- [x] Unit tests for core functionality
- [x] Integration tests for function calling
- [x] Tests for JSON mode and safety settings

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
