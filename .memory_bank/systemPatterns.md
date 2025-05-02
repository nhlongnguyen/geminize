# System Patterns

## Design Patterns

### Singleton Pattern

- Used for the `Configuration` class to ensure a single global configuration instance.
- Implemented using Ruby's `Singleton` module.

### Builder Pattern

- Employed in `RequestBuilder` to construct API requests.
- Separates request construction from execution.

### Factory Methods

- Used throughout the codebase to instantiate model objects from API responses.
- Example: `Models::ContentResponse.from_hash(response_data)`

### Repository Pattern

- Implemented in `ConversationRepository` for conversation persistence.
- Abstracts storage details from the conversation service.

### Adapter Pattern

- Used to adapt various image sources (files, URLs, raw bytes) to a common format.

### Strategy Pattern

- Applied in streaming responses with different processing modes (raw, incremental, delta).
- Allows clients to choose how streaming data is processed.

## Core Architectural Principles

### Separation of Concerns

- Each class has a single, well-defined responsibility.
- Examples: `Client` handles HTTP, `TextGeneration` handles generation logic.

### Immutable Objects

- Response objects are designed to be immutable.
- Request objects are built incrementally but not modified after submission.

### Comprehensive Validation

- Input validation happens before API calls.
- Extensive parameter checking and error handling.

### Error Handling

- Structured hierarchy of error classes.
- Detailed error messages with relevant context.
- Translation of API errors to gem-specific errors.

### Configuration Flexibility

- Multiple configuration approaches (env vars, block config).
- Sensible defaults with override capabilities.

### Developer Experience

- Method signatures follow Ruby idioms.
- Clear documentation with usage examples.
- Consistent return values and error handling.

## Code Organization

### Module Structure

- Everything contained within the `Geminize` namespace.
- Logical grouping of related functionality.

### Dependency Management

- Minimal external dependencies.
- Clear version requirements.

### Testing Approach

- RSpec for unit and integration tests.
- VCR for recording and replaying HTTP interactions.
- Comprehensive test coverage.

### Documentation

- YARD documentation for all public methods.
- Usage examples throughout codebase.
- Clear README with quickstart and detailed examples.
