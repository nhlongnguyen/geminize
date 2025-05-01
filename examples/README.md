# Geminize Examples

This directory contains example Ruby scripts demonstrating various features of the Geminize gem.

## Prerequisites

Before running these examples, ensure you have:

1.  **Ruby installed** (version 3.1.0 or later recommended).
2.  **Bundler installed** (`gem install bundler`).
3.  **Project dependencies installed**: Run `bundle install` from the project root directory (`../`).
4.  **Google Gemini API Key configured**: Create a `.env` file in the project root (`../`) by copying `.env.example` and adding your API key:
    ```bash
    # In ../.env
    GOOGLE_AI_API_KEY=your_api_key_here
    ```
    Alternatively, ensure the `GEMINI_API_KEY` environment variable is set.

## Running Examples

All examples should be run from the **project root directory** (the directory containing the main `Gemfile`, not this `examples/` directory).

### 1. Configuration (`configuration.rb`)

Demonstrates different ways to configure the Geminize client.

```bash
ruby examples/configuration.rb
```

### 2. Embeddings (`embeddings.rb`)

Shows how to generate text embeddings and calculate cosine similarity.

```bash
ruby examples/embeddings.rb
```

### 3. Multimodal (`multimodal.rb`)

Illustrates sending text and image inputs to the Gemini API.

_Note: You may need to update the image file paths within the script (`path/to/image.jpg`) to point to actual image files on your system._

```bash
ruby examples/multimodal.rb
```

### 4. Rails Initializer (`rails_initializer.rb`)

Shows the configuration structure typically used in a Rails initializer (this script is meant for illustration and doesn't require a Rails app to run).

```bash
ruby examples/rails_initializer.rb
```

### 5. System Instructions (`system_instructions.rb`)

Demonstrates using system instructions to guide the model's behavior and personality.

```bash
ruby examples/system_instructions.rb
```

### 6. Rails Chat Application (`rails_chat/`)

This directory contains a sample Rails application demonstrating Geminize integration. It requires a separate setup:

1.  Navigate into the directory: `cd examples/rails_chat`
2.  Install dependencies: `bundle install`
3.  Run database migrations (if applicable): `rails db:migrate`
4.  Start the Rails server: `rails server`
5.  Open your web browser to `http://localhost:3000`

Refer to the README within the `rails_chat/` directory (if available) for more specific instructions.
