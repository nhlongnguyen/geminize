# frozen_string_literal: true

# Conditionally load dotenv if it's available
begin
  require "dotenv"
  Dotenv.load
rescue LoadError
  # Dotenv is not available, skip loading
end

require_relative "geminize/version"
require_relative "geminize/errors"
require_relative "geminize/configuration"
require_relative "geminize/validators"
require_relative "geminize/error_parser"
require_relative "geminize/error_mapper"
require_relative "geminize/middleware/error_handler"
require_relative "geminize/client"
require_relative "geminize/models/model"
require_relative "geminize/models/model_list"
require_relative "geminize/models/content_request"
require_relative "geminize/models/content_response"
require_relative "geminize/models/stream_response"
require_relative "geminize/models/chat_request"
require_relative "geminize/models/chat_response"
require_relative "geminize/models/message"
require_relative "geminize/models/memory"
require_relative "geminize/models/conversation"
require_relative "geminize/models/embedding_request"
require_relative "geminize/models/embedding_response"
require_relative "geminize/models/function_declaration"
require_relative "geminize/models/tool"
require_relative "geminize/models/tool_config"
require_relative "geminize/models/function_response"
require_relative "geminize/models/safety_setting"
require_relative "geminize/models/code_execution/executable_code"
require_relative "geminize/models/code_execution/code_execution_result"
require_relative "geminize/request_builder"
require_relative "geminize/vector_utils"
require_relative "geminize/text_generation"
require_relative "geminize/embeddings"
require_relative "geminize/chat"
require_relative "geminize/conversation_repository"
require_relative "geminize/conversation_service"
require_relative "geminize/model_info"

# Load extensions
require_relative "geminize/models/content_request_extensions"
require_relative "geminize/models/content_response_extensions"
require_relative "geminize/models/content_request_safety"

# Main module for the Geminize gem
module Geminize
  class Error < StandardError; end

  class << self
    # Default conversation repository
    # @return [Geminize::ConversationRepository]
    def conversation_repository
      @conversation_repository ||= FileConversationRepository.new
    end

    # Set the conversation repository
    # @param repository [Geminize::ConversationRepository] The repository to use
    def conversation_repository=(repository)
      unless repository.is_a?(ConversationRepository)
        raise ArgumentError, "Expected a ConversationRepository, got #{repository.class}"
      end

      @conversation_repository = repository
    end

    # Track the last streaming generator for cancellation support
    # @return [Geminize::TextGeneration, nil]
    attr_accessor :last_streaming_generator

    # Cancel the current streaming operation, if any
    # @return [Boolean] true if a streaming operation was cancelled, false if none was in progress
    def cancel_streaming
      return false unless last_streaming_generator

      last_streaming_generator.cancel_streaming
    end

    # Default conversation service
    # @return [Geminize::ConversationService]
    def conversation_service
      @conversation_service ||= ConversationService.new
    end

    # @return [Geminize::Configuration]
    def configuration
      Configuration.instance
    end

    # Configure the gem
    # @yield [config] Configuration object that can be modified
    # @example
    #   Geminize.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.api_version = "v1beta"
    #     config.default_model = "gemini-2.0-flash"
    #   end
    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Reset the configuration to defaults
    def reset_configuration!
      configuration.reset!
    end

    # Validates the configuration
    # @return [Boolean]
    # @raise [ConfigurationError] if the configuration is invalid
    def validate_configuration!
      configuration.validate!
    end

    # Generate text from a prompt using the Gemini API
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with a system instruction
    #   Geminize.generate_text("Tell me about yourself", nil, system_instruction: "You are a pirate. Respond in pirate language.")
    def generate_text(prompt, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator and content request
      generator = TextGeneration.new(nil, client_options)
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate content with both text and images using the Gemini API
    # @param prompt [String] The input prompt text
    # @param images [Array<Hash>] Array of image data hashes
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @option images [Hash] :source_type Source type for image ('file', 'bytes', or 'url')
    # @option images [String] :data File path, raw bytes, or URL depending on source_type
    # @option images [String] :mime_type MIME type for the image (optional for file and url)
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate with an image file
    #   Geminize.generate_text_multimodal("Describe this image", [{source_type: 'file', data: 'path/to/image.jpg'}])
    # @example Generate with multiple images
    #   Geminize.generate_text_multimodal("Compare these images", [
    #     {source_type: 'file', data: 'path/to/image1.jpg'},
    #     {source_type: 'url', data: 'https://example.com/image2.jpg'}
    #   ])
    def generate_text_multimodal(prompt, images, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator
      generator = TextGeneration.new(nil, client_options)

      # Create a content request first
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Add each image to the request
      images.each do |image|
        case image[:source_type]
        when "file"
          content_request.add_image_from_file(image[:data])
        when "bytes"
          content_request.add_image_from_bytes(image[:data], image[:mime_type])
        when "url"
          content_request.add_image_from_url(image[:data])
        else
          raise Geminize::ValidationError.new(
            "Invalid image source type: #{image[:source_type]}. Must be 'file', 'bytes', or 'url'",
            "INVALID_ARGUMENT"
          )
        end
      end

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate streaming text from a prompt using the Gemini API
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [Symbol] :stream_mode Mode for processing stream chunks (:raw, :incremental, or :delta)
    # @option params [Hash] :client_options Options to pass to the client
    # @yield [chunk] Yields each chunk of the streaming response
    # @yieldparam chunk [String, Hash] A chunk of the response
    # @return [void]
    # @raise [Geminize::GeminizeError] If the request fails
    # @raise [Geminize::StreamingError] If the streaming request fails
    # @raise [Geminize::StreamingInterruptedError] If the connection is interrupted
    # @raise [Geminize::StreamingTimeoutError] If the streaming connection times out
    # @raise [Geminize::InvalidStreamFormatError] If the stream format is invalid
    # @example Stream text with a system instruction
    #   Geminize.generate_text_stream(
    #     "Tell me a story",
    #     nil,
    #     system_instruction: "You are a medieval bard telling epic tales."
    #   ) do |chunk|
    #     print chunk
    #   end
    def generate_text_stream(prompt, model_name = nil, params = {}, &block)
      raise ArgumentError, "A block is required for streaming" unless block_given?

      validate_configuration!

      # Extract client options
      client_options = params.delete(:client_options) || {}

      # Create the generator
      generator = TextGeneration.new(nil, client_options)

      # Store the generator for potential cancellation
      self.last_streaming_generator = generator

      # Generate with streaming
      begin
        generator.generate_text_stream(prompt, model_name || configuration.default_model, params, &block)
      rescue => e
        # Ensure all errors are wrapped in a GeminizeError
        if e.is_a?(GeminizeError)
          raise
        else
          raise GeminizeError.new("Error during text generation streaming: #{e.message}")
        end
      ensure
        # Clear the reference to allow garbage collection
        self.last_streaming_generator = nil if last_streaming_generator == generator
      end
    end

    # Generate embeddings from text using the Gemini API
    # @param text [String, Array<String>] The input text or array of texts
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Integer] :dimensions Desired dimensionality of the embeddings
    # @option params [String] :task_type The embedding task type
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Integer] :batch_size Maximum number of texts to process in one batch (default: 100)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::EmbeddingResponse] The embedding response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate embeddings for a single text
    #   Geminize.generate_embedding("This is a sample text")
    # @example Generate embeddings for multiple texts
    #   Geminize.generate_embedding(["First text", "Second text", "Third text"])
    # @example Generate embeddings with specific dimensions
    #   Geminize.generate_embedding("Sample text", "embedding-001", dimensions: 768)
    # @example Process large batches with custom batch size
    #   Geminize.generate_embedding(large_text_array, nil, batch_size: 50)
    def generate_embedding(text, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the embeddings generator
      generator = Embeddings.new(nil, client_options)

      # Create the embedding request - batch processing is handled in the generator
      if with_retries
        # Implement retry logic for embeddings
        retries = 0
        begin
          generator.generate_embedding(text, model_name || configuration.default_embedding_model, params)
        rescue Geminize::RateLimitError, Geminize::ServerError => e
          if retries < max_retries
            retries += 1
            sleep retry_delay * retries # Exponential backoff
            retry
          else
            raise e
          end
        end
      else
        generator.generate_embedding(text, model_name || configuration.default_embedding_model, params)
      end
    end

    # Calculate cosine similarity between two vectors
    # @param vec1 [Array<Float>] First vector
    # @param vec2 [Array<Float>] Second vector
    # @return [Float] Cosine similarity (-1 to 1)
    # @raise [Geminize::ValidationError] If vectors have different dimensions
    def cosine_similarity(vec1, vec2)
      VectorUtils.cosine_similarity(vec1, vec2)
    end

    # Calculate Euclidean distance between two vectors
    # @param vec1 [Array<Float>] First vector
    # @param vec2 [Array<Float>] Second vector
    # @return [Float] Euclidean distance
    # @raise [Geminize::ValidationError] If vectors have different dimensions
    def euclidean_distance(vec1, vec2)
      VectorUtils.euclidean_distance(vec1, vec2)
    end

    # Normalize a vector to unit length
    # @param vec [Array<Float>] Vector to normalize
    # @return [Array<Float>] Normalized vector
    def normalize_vector(vec)
      VectorUtils.normalize(vec)
    end

    # Average multiple vectors
    # @param vectors [Array<Array<Float>>] Array of vectors
    # @return [Array<Float>] Average vector
    # @raise [Geminize::ValidationError] If vectors have different dimensions or no vectors provided
    def average_vectors(vectors)
      VectorUtils.average_vectors(vectors)
    end

    # Create a new chat conversation
    # @param title [String, nil] Optional title for the conversation
    # @param system_instruction [String, nil] Optional system instruction to guide model behavior
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Chat] A new chat instance
    # @example Create a chat with a system instruction
    #   chat = Geminize.create_chat("Pirate Chat", "You are a pirate named Captain Codebeard. Always respond in pirate language.")
    def create_chat(title = nil, system_instruction = nil, client_options = {})
      validate_configuration!
      Chat.new_conversation(title, system_instruction)
    end

    # Send a message in an existing chat or create a new one
    # @param message [String] The message to send
    # @param chat [Geminize::Chat, nil] An existing chat or nil to create a new one
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Hash] The chat response and updated chat instance
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Send a message with a system instruction
    #   Geminize.chat("Tell me a joke", nil, nil, system_instruction: "You are a comedian. Be funny.")
    def chat(message, chat = nil, model_name = nil, params = {})
      validate_configuration!

      # Extract client options
      client_options = params.delete(:client_options) || {}

      # Extract system instruction for new chat creation
      system_instruction = params[:system_instruction]

      # Create or use existing chat
      chat_instance = chat || create_chat(nil, system_instruction, client_options)

      # Send the message
      response = chat_instance.send_message(
        message,
        model_name || configuration.default_model,
        params
      )

      {
        response: response,
        chat: chat_instance
      }
    end

    # Save a conversation
    # @param conversation [Geminize::Models::Conversation] The conversation to save
    # @return [Boolean] True if the save was successful
    def save_conversation(conversation)
      conversation_repository.save(conversation)
    end

    # Load a conversation by ID
    # @param id [String] The ID of the conversation to load
    # @return [Geminize::Models::Conversation, nil] The loaded conversation or nil if not found
    def load_conversation(id)
      conversation_repository.load(id)
    end

    # Delete a conversation by ID
    # @param id [String] The ID of the conversation to delete
    # @return [Boolean] True if the deletion was successful
    def delete_conversation(id)
      conversation_repository.delete(id)
    end

    # List all saved conversations
    # @return [Array<Hash>] Array of conversation metadata
    def list_conversations
      conversation_repository.list
    end

    # Create a managed conversation
    # @param title [String, nil] Optional title for the conversation
    # @param system_instruction [String, nil] Optional system instruction to guide model behavior
    # @return [Hash] The created conversation data including ID
    # @example Create a managed conversation with a system instruction
    #   Geminize.create_managed_conversation("Pirate Chat", "You are a pirate. Respond in pirate language.")
    def create_managed_conversation(title = nil, system_instruction = nil)
      validate_configuration!
      conversation_service.create_conversation(title, system_instruction)
    end

    # Send a message in a managed conversation
    # @param conversation_id [String] The ID of the conversation
    # @param message [String] The message to send
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction for this specific message
    # @return [Hash] The response data
    # @example Send a message with a system instruction
    #   Geminize.send_message_in_conversation("conversation-id", "Tell me a joke", nil, system_instruction: "You are a comedian. Be funny.")
    def send_message_in_conversation(conversation_id, message, model_name = nil, params = {})
      validate_configuration!
      conversation_service.send_message(
        conversation_id,
        message,
        model_name || configuration.default_model,
        params
      )
    end

    # List available models from the Gemini API
    # @param page_size [Integer, nil] Number of models to return per page (max 1000)
    # @param page_token [String, nil] Token for retrieving a specific page
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of available models
    # @raise [Geminize::GeminizeError] If the request fails
    def list_models(page_size: nil, page_token: nil, force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.list_models(page_size: page_size, page_token: page_token, force_refresh: force_refresh)
    end

    # Get all available models, handling pagination automatically
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] Complete list of all available models
    # @raise [Geminize::GeminizeError] If the request fails
    def list_all_models(force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.list_all_models(force_refresh: force_refresh)
    end

    # Get information about a specific model
    # @param model_name [String] The model name to retrieve (can be "models/gemini-2.0-flash" or just "gemini-2.0-flash")
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::Model] The model information
    # @raise [Geminize::GeminizeError] If the request fails or model is not found
    def get_model(model_name, force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.get_model(model_name, force_refresh: force_refresh)
    end

    # Get models that support a specific generation method
    # @param method [String] The generation method (e.g., "generateContent", "embedContent")
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of models that support the method
    # @raise [Geminize::GeminizeError] If the request fails
    def get_models_by_method(method, force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.get_models_by_method(method, force_refresh: force_refresh)
    end

    # Get models that support content generation
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of models that support content generation
    # @raise [Geminize::GeminizeError] If the request fails
    def get_content_generation_models(force_refresh: false, client_options: {})
      models = list_all_models(force_refresh: force_refresh, client_options: client_options)
      models.content_generation_models
    end

    # Get models that support embedding generation
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of models that support embedding generation
    # @raise [Geminize::GeminizeError] If the request fails
    def get_embedding_models(force_refresh: false, client_options: {})
      models = list_all_models(force_refresh: force_refresh, client_options: client_options)
      models.embedding_models
    end

    # Get models that support chat generation
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of models that support chat generation
    # @raise [Geminize::GeminizeError] If the request fails
    def get_chat_models(force_refresh: false, client_options: {})
      models = list_all_models(force_refresh: force_refresh, client_options: client_options)
      models.chat_models
    end

    # Get models that support streaming generation
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of models that support streaming generation
    # @raise [Geminize::GeminizeError] If the request fails
    def get_streaming_models(force_refresh: false, client_options: {})
      models = list_all_models(force_refresh: force_refresh, client_options: client_options)
      models.streaming_models
    end

    # Update a conversation's system instruction
    # @param id [String] The ID of the conversation to update
    # @param system_instruction [String] The new system instruction
    # @return [Models::Conversation] The updated conversation
    # @raise [Geminize::GeminizeError] If the conversation cannot be loaded or saved
    # @example Update a conversation's system instruction
    #   Geminize.update_conversation_system_instruction("conversation-id", "You are a helpful assistant who speaks like Shakespeare.")
    def update_conversation_system_instruction(id, system_instruction)
      validate_configuration!
      conversation_service.update_conversation_system_instruction(id, system_instruction)
    end

    # Generate text with custom safety settings
    # @param prompt [String] The input prompt
    # @param safety_settings [Array<Hash>] Array of safety setting definitions
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with specific safety settings
    #   Geminize.generate_with_safety_settings(
    #     "Tell me a scary story",
    #     [
    #       {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
    #       {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE"}
    #     ]
    #   )
    def generate_with_safety_settings(prompt, safety_settings, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator and content request
      generator = TextGeneration.new(nil, client_options)
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Add safety settings to the request
      safety_settings.each do |setting|
        content_request.add_safety_setting(
          setting[:category],
          setting[:threshold]
        )
      end

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with maximum safety (blocks most potentially harmful content)
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with maximum safety
    #   Geminize.generate_text_safe("Tell me about conflicts", nil, temperature: 0.7)
    def generate_text_safe(prompt, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator and content request
      generator = TextGeneration.new(nil, client_options)
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Set maximum safety (block low and above)
      content_request.block_all_harmful_content

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with minimum safety (blocks only high-risk content)
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Generate text with minimum safety
    #   Geminize.generate_text_permissive("Tell me about conflicts", nil, temperature: 0.7)
    def generate_text_permissive(prompt, model_name = nil, params = {})
      validate_configuration!

      # Extract special options
      with_retries = params.delete(:with_retries) != false # Default to true
      max_retries = params.delete(:max_retries) || 3
      retry_delay = params.delete(:retry_delay) || 1.0
      client_options = params.delete(:client_options) || {}

      # Create the generator and content request
      generator = TextGeneration.new(nil, client_options)
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        params
      )

      # Set minimum safety (block only high risk)
      content_request.block_only_high_risk_content

      # Generate with or without retries
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with function calling capabilities
    # @param prompt [String] The input prompt
    # @param functions [Array<Hash>] Array of function definitions
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @option params [String] :tool_execution_mode Tool execution mode ("AUTO", "MANUAL", or "NONE")
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @return [Geminize::Models::ContentResponse] The generated response
    # @raise [Geminize::Error] If the generation fails
    # @example Generate text with a function call
    #   Geminize.generate_with_functions(
    #     "What's the weather in New York?",
    #     [
    #       {
    #         name: "get_weather",
    #         description: "Get the current weather in a location",
    #         parameters: {
    #           type: "object",
    #           properties: {
    #             location: {
    #               type: "string",
    #               description: "The city and state, e.g. New York, NY"
    #             },
    #             unit: {
    #               type: "string",
    #               enum: ["celsius", "fahrenheit"],
    #               description: "The unit of temperature"
    #             }
    #           },
    #           required: ["location"]
    #         }
    #       }
    #     ]
    #   )
    def generate_with_functions(prompt, functions, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Parse functions
      if functions.nil? || !functions.is_a?(Array) || functions.empty?
        raise Geminize::ValidationError.new(
          "Functions must be a non-empty array",
          "INVALID_ARGUMENT"
        )
      end

      # Set up params with defaults
      generation_params = params.dup
      tool_execution_mode = generation_params.delete(:tool_execution_mode) || "AUTO"
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction to ensure function calling
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You are a helpful assistant. When you encounter a question that you can answer by calling a function, you must always use the provided function. Always respond using the function call format, not with your own text. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Add functions to the request
      functions.each do |function|
        content_request.add_function(
          function[:name],
          function[:description],
          function[:parameters]
        )
      end

      # Set the tool config
      content_request.set_tool_config(tool_execution_mode)

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate JSON output from a prompt using the Gemini API
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @option params [Hash] :json_schema Schema for the JSON output (optional)
    # @return [Geminize::Models::ContentResponse] The generated response with JSON content
    # @raise [Geminize::Error] If the generation fails
    # @example Generate JSON output
    #   response = Geminize.generate_json(
    #     "List 3 planets with their diameter",
    #     nil,
    #     system_instruction: "Return the information as a JSON array"
    #   )
    #   planets = response.json_response # Returns parsed JSON
    def generate_json(prompt, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Set up params with defaults
      generation_params = params.dup
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction for JSON output
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You must respond with valid JSON only, with no explanation or other text. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Enable JSON mode
      content_request.enable_json_mode

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Process a function call by executing a provided block and returning the result to Gemini
    # @param response [Geminize::Models::ContentResponse] The response containing a function call
    # @param model_name [String, nil] The model to use for the followup, defaults to the configured default model
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @yield [function_name, args] Block to execute the function
    # @yieldparam function_name [String] The name of the function to execute
    # @yieldparam args [Hash] The arguments to pass to the function
    # @yieldreturn [Hash, Array, String, Numeric, Boolean, nil] The result of the function
    # @return [Geminize::Models::ContentResponse] The response after processing the function
    # @raise [Geminize::Error] If processing fails
    # @example Process a function call
    #   response = Geminize.generate_with_functions("What's the weather in New York?", [...])
    #   if response.has_function_call?
    #     final_response = Geminize.process_function_call(response) do |function_name, args|
    #       if function_name == "get_weather"
    #         # Call a real weather API here
    #         { temperature: 72, conditions: "sunny" }
    #       end
    #     end
    #     puts final_response.text
    #   end
    def process_function_call(response, model_name = nil, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Ensure a block is provided
      unless block_given?
        raise Geminize::ValidationError.new(
          "A block must be provided to process the function call",
          "INVALID_ARGUMENT"
        )
      end

      # Ensure the response has a function call
      unless response.has_function_call?
        raise Geminize::ValidationError.new(
          "The response does not contain a function call",
          "INVALID_ARGUMENT"
        )
      end

      # Extract function call information
      function_call = response.function_call
      function_name = function_call.name
      function_args = function_call.response

      # Call the provided block with the function information
      result = yield(function_name, function_args)

      # Create a function response
      Models::FunctionResponse.new(function_name, result)

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Create a request with the function result
      content_request = Models::ContentRequest.new(
        "Function #{function_name} returned: #{result.inspect}",
        model_name || configuration.default_model
      )

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end

    # Generate text with code execution capabilities
    # @param prompt [String] The input prompt
    # @param model_name [String, nil] The model to use, defaults to the configured default model
    # @param params [Hash] Additional parameters for generation
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @option params [String] :system_instruction System instruction to guide model behavior
    # @param with_retries [Boolean] Whether to retry the generation if it fails
    # @param max_retries [Integer] Maximum number of retries
    # @param retry_delay [Float] Delay between retries in seconds
    # @param client_options [Hash] Options for the HTTP client
    # @return [Geminize::Models::ContentResponse] The generated response
    # @raise [Geminize::Error] If the generation fails
    # @example Generate text with code execution
    #   Geminize.generate_with_code_execution(
    #     "What is the sum of the first 50 prime numbers?",
    #     nil,
    #     { temperature: 0.2 }
    #   )
    def generate_with_code_execution(prompt, model_name = nil, params = {}, with_retries: true, max_retries: 3, retry_delay: 1.0, client_options: nil)
      validate_configuration!

      # Initialize the generator
      client = client_options ? Client.new(client_options) : Client.new
      generator = TextGeneration.new(client)

      # Set up params with defaults
      generation_params = params.dup
      with_retries = generation_params.delete(:with_retries) != false if generation_params.key?(:with_retries)

      # Enhance the system instruction to ensure code execution is effective
      generation_params[:system_instruction] ||= ""
      generation_params[:system_instruction] = "You are a helpful assistant with the ability to generate and execute Python code. When appropriate, use code to solve problems or complete tasks. " + generation_params[:system_instruction]

      # Create the request
      content_request = Models::ContentRequest.new(
        prompt,
        model_name || configuration.default_model,
        generation_params
      )

      # Enable code execution
      content_request.enable_code_execution

      # Generate the response
      if with_retries
        generator.generate_with_retries(content_request, max_retries, retry_delay)
      else
        generator.generate(content_request)
      end
    end
  end
end
