# Geminize Examples

This directory contains example Ruby scripts demonstrating various features of the Geminize gem.

## Prerequisites

Before running these examples, ensure you have:

1.  **Ruby installed** (version 3.1.0 or later recommended).
2.  **Bundler installed** (`gem install bundler`).
3.  **Project dependencies installed**: Run `bundle install` from the project root directory (`../`).
4.  **Google Gemini API Key configured**: Create a `.env` file in the project root (`../`) by copying `.env.example` and adding your API key:
    ```bash
    # In .env
    GEMINI_API_KEY=your_api_key_here
    ```

## Running Examples

All examples should be run from the **project root directory** (the directory containing the main `Gemfile`, not this `examples/` directory).

### 1. Configuration (`configuration.rb`)

Demonstrates different ways to configure the Geminize client.

```bash
bundle exec ruby examples/configuration.rb
```

### 2. Embeddings (`embeddings.rb`)

Shows how to generate text embeddings and calculate cosine similarity.

```bash
bundle exec ruby examples/embeddings.rb
```

### 3. Multimodal (`multimodal.rb`)

Illustrates sending text and image inputs to the Gemini API.

_Note: You may need to update the image file paths within the script (`path/to/image.jpg`) to point to actual image files on your system._

```bash
bundle exec ruby examples/multimodal.rb
```

### 4. System Instructions (`system_instructions.rb`)

Demonstrates using system instructions to guide the model's behavior and personality.

```bash
bundle exec ruby examples/system_instructions.rb
```
