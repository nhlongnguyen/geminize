## [1.1.0] - 2025-05-02

### Added

- Comprehensive Models API for discovering and filtering Gemini models
  - Added `list_models` and `list_all_models` methods for retrieving available models
  - Added `get_model` method for fetching specific model details
  - Added filtering methods to find models by capability:
    - `get_content_generation_models`
    - `get_embedding_models`
    - `get_chat_models`
    - `get_streaming_models`
  - Added `get_models_by_method` to filter by specific generation methods
  - Extended `ModelList` class with comprehensive filtering capabilities
  - Added model capability inspection methods
  - Implemented pagination support for model listing
  - Added caching for model information to reduce API calls
  - Added comprehensive VCR tests for Models API functionality
  - Updated documentation with Models API examples

## [1.0.0] - 2025-05-02

### Removed

- Removed Rails-related integration from the gem, simplifying usage.

## [0.1.1] - 2025-05-01

### Added

- Rails integration for easy use in Rails applications
  - Rails engine for seamless integration
  - Generator for creating configuration initializers
  - Controller concerns for Gemini operations
  - View helpers for rendering conversations and chat interfaces
  - Comprehensive documentation and examples
- Multimodal support for sending mixed content including text and images to the Gemini API
- New `generate_text_multimodal` method at module level for simplified multimodal requests
- Methods for adding images to content requests from files, URLs, or raw bytes
- Support for common image formats (JPEG, PNG, GIF, WEBP) with proper MIME type detection
- Comprehensive validation for image formats, sizes, and content
- New example file demonstrating multimodal usage
- Extended embedding support with all Google AI task types:
  - Added `TASK_TYPE_UNSPECIFIED`, `QUESTION_ANSWERING`, `FACT_VERIFICATION`, and `CODE_RETRIEVAL_QUERY` task types
  - Updated examples and documentation to demonstrate all task types
  - Added tests for all new task types

## [0.1.0] - 2025-04-21

- Initial release
