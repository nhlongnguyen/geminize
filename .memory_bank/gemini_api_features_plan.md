# Gemini API Features Implementation Plan

## Overview

This plan outlines the implementation of missing features from the Google Generative AI API that are not yet present in the Geminize gem. Based on the documentation at https://ai.google.dev/api/generate-content, several capabilities need to be added to bring the gem up to date with the latest API capabilities.

## Requirements Analysis

1. **Function Calling**: The Gemini API supports function/tool calling for agents, which is not implemented in the gem.
2. **JSON Mode**: The API supports dedicated JSON mode for structured outputs.
3. **Code Execution**: Capabilities for running and executing code segments.
4. **Advanced Safety Settings**: Comprehensive control over safety thresholds.
5. **Additional Content Types**: Support for audio, PDF/documents, and video inputs.
6. **Caching Support**: API caching capabilities for enhanced performance.

## Components Affected

- `ContentRequest` class for request creation
- `RequestBuilder` module for API request formatting
- Response models for handling new response types
- Main `Geminize` module for convenience methods

## Implementation Strategy

The implementation will follow a phased approach, focusing on high-value features first:

### Phase 1: Function Calling & JSON Mode

1. **Function Calling Implementation**:

   - Create new model classes for function definitions
   - Add function declaration support to `ContentRequest`
   - Update request builder to include function information
   - Update response models to handle function responses

2. **JSON Mode Implementation**:
   - Add MIME type support for JSON responses
   - Implement new helper methods for JSON generation
   - Add validation for JSON response structures

### Phase 2: Safety Settings & Code Execution

1. **Safety Settings Implementation**:

   - Add `SafetySetting` model for configuration
   - Implement safety controls in request generation
   - Add module-level methods for safety configuration

2. **Code Execution Implementation**:
   - Create model classes for code execution settings
   - Implement tools for code execution in `ContentRequest`
   - Update request builders and response handlers

### Phase 3: Additional Content Types

1. **Audio Support**:

   - Add methods for audio input in `ContentRequest`
   - Implement validation for audio content
   - Add MIME type detection for audio files

2. **Document/PDF Support**:

   - Add methods for document input in `ContentRequest`
   - Implement validation for document content
   - Add MIME type detection for document files

3. **Video Support**:
   - Add methods for video input in `ContentRequest`
   - Implement validation for video content
   - Add MIME type detection for video files

### Phase 4: Caching & Optimization

1. **Caching Implementation**:
   - Add caching support to requests
   - Implement cached content handling
   - Add module-level methods for caching control

## Detailed Implementation Steps

### Function Calling

```ruby
# Create models for function calling
module Geminize
  module Models
    class FunctionDeclaration
      attr_reader :name, :description, :parameters
      # Implementation...
    end

    class Tool
      attr_reader :function_declarations
      # Implementation...
    end

    class ToolConfig
      attr_reader :execution_mode
      # Implementation...
    end
  end
end

# Add to ContentRequest class
def add_function(name, description, parameters)
  @functions ||= []
  @functions << Models::FunctionDeclaration.new(name, description, parameters)
  self
end

def set_tool_config(execution_mode)
  @tool_config = Models::ToolConfig.new(execution_mode)
  self
end

# Updates to request builder
# Updates to response handling
```

### JSON Mode

```ruby
# Add to ContentRequest class
attr_accessor :response_mime_type

def enable_json_mode
  @response_mime_type = "application/json"
  self
end

# Add to module methods
def generate_json(prompt, model_name = nil, params = {})
  # Implementation...
end
```

## Dependencies

- Gemini API version compatibility
- MIME type detection for new content types
- JSON schema validation for function parameters

## Challenges & Mitigations

1. **API Changes**: The Gemini API is evolving rapidly

   - Mitigation: Design flexible abstractions that can adapt to API changes

2. **Compatibility**: Ensuring backward compatibility for existing users

   - Mitigation: Add new features without changing existing method signatures

3. **Testing Complexity**: Testing new capabilities requires more complex fixtures

   - Mitigation: Create comprehensive VCR cassettes and mock response structures

4. **Performance**: Adding features might impact performance
   - Mitigation: Focus on lazy loading and efficiency in implementation

## Creative Phase Components

The following components will require more design exploration:

1. **Function Calling Interface**: Designing an intuitive, Ruby-idiomatic interface for function declarations
2. **Content Type Handling**: Creating a unified approach to handling diverse content types
3. **Safety Settings UI**: Designing a clear interface for configuring safety thresholds

## Testing Strategy

1. **Unit Tests**: Test each new component in isolation
2. **Integration Tests**: Test the integration with the Gemini API
3. **VCR Tests**: Record API interactions for reliable testing
4. **Edge Cases**: Test error conditions and boundary values

## Documentation Plan

1. Update YARD documentation for all new methods
2. Create example scripts for each new feature
3. Update the README with new capabilities
4. Add architecture diagrams for complex features (e.g., function calling)

## Timeline Estimate

- **Phase 1**: 1-2 weeks
- **Phase 2**: 1-2 weeks
- **Phase 3**: 2-3 weeks
- **Phase 4**: 1 week

## Dependencies

- Current implementation of ContentRequest and related classes
- Testing infrastructure for VCR tests
- Documentation system for YARD integration

## Next Steps

1. Update tasks.md with detailed implementation tasks
2. Begin implementation of function calling support
3. Create example scripts for testing new features
4. Update test fixtures for new capabilities
