# frozen_string_literal: true

# Geminize Configuration
#
# This file contains the configuration for the Geminize gem.
# It is used to set up the Google Gemini API integration.

Geminize.configure do |config|
  # Your Google Gemini API key
  # You can get one from https://ai.google.dev/
  # Can also be set via GEMINI_API_KEY environment variable
  # config.api_key = ENV.fetch("GEMINI_API_KEY", nil)

  # The API version to use (default: v1beta)
  # config.api_version = "v1beta"

  # The default model to use (default: gemini-1.5-pro-latest)
  # config.default_model = "gemini-1.5-pro-latest"

  # The base URL for the Gemini API (default: https://generativelanguage.googleapis.com)
  # config.api_base_url = "https://generativelanguage.googleapis.com"

  # Logging level for Geminize (default: :info)
  # Valid values: :debug, :info, :warn, :error, :fatal
  # config.log_level = Rails.env.production? ? :info : :debug

  # Where to store conversation data (default: Rails.root.join("tmp", "conversations"))
  # Only applicable when using FileConversationRepository
  # config.conversations_path = Rails.root.join("tmp", "conversations")

  # Default parameters for text generation
  # config.generation_defaults = {
  #   temperature: 0.7,
  #   max_tokens: 500,
  #   top_p: 0.95,
  #   top_k: 40
  # }
end
