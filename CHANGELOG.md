## [0.1.1]

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
