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
require_relative "geminize/request_builder"
require_relative "geminize/vector_utils"
require_relative "geminize/text_generation"
require_relative "geminize/embeddings"
require_relative "geminize/chat"
require_relative "geminize/conversation_repository"
require_relative "geminize/conversation_service"
require_relative "geminize/model_info"


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
    #     config.default_model = "gemini-1.5-pro-latest"
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

    # Get a list of available models from the Gemini API
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::ModelList] List of available models
    # @raise [Geminize::GeminizeError] If the request fails
    # @example Get a list of all available models
    #   models = Geminize.list_models
    # @example Get a fresh list bypassing cache
    #   models = Geminize.list_models(force_refresh: true)
    # @example Filter models by capability
    #   vision_models = Geminize.list_models.vision_models
    def list_models(force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.list_models(force_refresh: force_refresh)
    end

    # Get information about a specific model
    # @param model_id [String] The model ID to retrieve
    # @param force_refresh [Boolean] Force a refresh from the API instead of using cache
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Models::Model] The model information
    # @raise [Geminize::GeminizeError] If the request fails or model is not found
    # @example Get information about a specific model
    #   model = Geminize.get_model("gemini-1.5-pro")
    def get_model(model_id, force_refresh: false, client_options: {})
      validate_configuration!
      model_info = ModelInfo.new(nil, client_options)
      model_info.get_model(model_id, force_refresh: force_refresh)
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
  end
end
