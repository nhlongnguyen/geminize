# frozen_string_literal: true

require_relative "geminize/version"
require_relative "geminize/errors"
require_relative "geminize/configuration"
require_relative "geminize/validators"
require_relative "geminize/error_parser"
require_relative "geminize/error_mapper"
require_relative "geminize/middleware/error_handler"
require_relative "geminize/client"
require_relative "geminize/models/content_request"
require_relative "geminize/models/content_response"
require_relative "geminize/models/chat_request"
require_relative "geminize/models/chat_response"
require_relative "geminize/models/message"
require_relative "geminize/models/memory"
require_relative "geminize/models/conversation"
require_relative "geminize/request_builder"
require_relative "geminize/text_generation"
require_relative "geminize/chat"
require_relative "geminize/conversation_repository"
require_relative "geminize/conversation_service"

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
    # @option params [Boolean] :with_retries Enable retries for transient errors (default: true)
    # @option params [Integer] :max_retries Maximum retry attempts (default: 3)
    # @option params [Float] :retry_delay Initial delay between retries in seconds (default: 1.0)
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Geminize::Models::ContentResponse] The generation response
    # @raise [Geminize::GeminizeError] If the request fails
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

    # Create a new chat conversation
    # @param title [String, nil] Optional title for the conversation
    # @param client_options [Hash] Options to pass to the client
    # @return [Geminize::Chat] A new chat instance
    def create_chat(title = nil, client_options = {})
      validate_configuration!
      Chat.new_conversation(title)
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
    # @option params [Hash] :client_options Options to pass to the client
    # @return [Hash] The chat response and updated chat instance
    # @raise [Geminize::GeminizeError] If the request fails
    def chat(message, chat = nil, model_name = nil, params = {})
      validate_configuration!

      # Extract client options
      client_options = params.delete(:client_options) || {}

      # Create or use existing chat
      chat_instance = chat || create_chat(nil, client_options)

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

    # List all available conversations
    # @return [Array<Hash>] An array of conversation metadata
    def list_conversations
      conversation_repository.list
    end

    # Create a new conversation using the conversation service
    # @param title [String, nil] Optional title for the conversation
    # @return [Geminize::Models::Conversation] The new conversation
    def create_managed_conversation(title = nil)
      validate_configuration!
      conversation_service.create_conversation(title)
    end

    # Send a message in a managed conversation
    # @param conversation_id [String] The ID of the conversation
    # @param message [String] The message to send
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @return [Hash] The response and updated conversation
    # @raise [Geminize::GeminizeError] If the request fails
    def send_message_in_conversation(conversation_id, message, model_name = nil, params = {})
      validate_configuration!
      conversation_service.send_message(conversation_id, message, model_name, params)
    end
  end
end
