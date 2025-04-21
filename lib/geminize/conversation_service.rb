# frozen_string_literal: true

module Geminize
  # High-level service for managing conversations
  class ConversationService
    # @return [Geminize::ConversationRepository] The repository for storing conversations
    attr_reader :repository

    # @return [Geminize::Client] The client instance
    attr_reader :client

    # Initialize a new conversation service
    # @param repository [Geminize::ConversationRepository, nil] The repository to use
    # @param client [Geminize::Client, nil] The client to use
    # @param options [Hash] Additional options
    def initialize(repository = nil, client = nil, options = {})
      @repository = repository || Geminize.conversation_repository
      @client = client || Client.new(options)
      @options = options
    end

    # Create a new conversation
    # @param title [String, nil] Optional title for the conversation
    # @return [Models::Conversation] The new conversation
    def create_conversation(title = nil)
      conversation = Models::Conversation.new(nil, title)
      @repository.save(conversation)
      conversation
    end

    # Get a conversation by ID
    # @param id [String] The ID of the conversation to get
    # @return [Models::Conversation, nil] The conversation or nil if not found
    # @raise [Geminize::GeminizeError] If the conversation cannot be loaded
    def get_conversation(id)
      @repository.load(id)
    end

    # Send a message in a conversation and get a response
    # @param conversation_id [String] The ID of the conversation
    # @param message [String] The message to send
    # @param model_name [String, nil] The model to use
    # @param params [Hash] Additional generation parameters
    # @return [Hash] The response and updated conversation
    # @raise [Geminize::GeminizeError] If the request fails
    def send_message(conversation_id, message, model_name = nil, params = {})
      # Load the conversation
      conversation = get_conversation(conversation_id)
      raise Geminize::GeminizeError.new("Conversation not found: #{conversation_id}", nil, nil) unless conversation

      # Create a chat instance with the conversation
      chat = Chat.new(conversation, @client, @options)

      # Send the message
      response = chat.send_message(message, model_name, params)

      # Save the updated conversation
      @repository.save(conversation)

      {
        response: response,
        conversation: conversation
      }
    end

    # List all available conversations
    # @return [Array<Hash>] An array of conversation metadata
    def list_conversations
      @repository.list
    end

    # Delete a conversation
    # @param id [String] The ID of the conversation to delete
    # @return [Boolean] True if the deletion was successful
    def delete_conversation(id)
      @repository.delete(id)
    end

    # Update a conversation title
    # @param id [String] The ID of the conversation to update
    # @param title [String] The new title
    # @return [Models::Conversation] The updated conversation
    # @raise [Geminize::GeminizeError] If the conversation cannot be loaded or saved
    def update_conversation_title(id, title)
      conversation = get_conversation(id)
      raise Geminize::GeminizeError.new("Conversation not found: #{id}", nil, nil) unless conversation

      conversation.title = title
      @repository.save(conversation)
      conversation
    end

    # Clear a conversation's message history
    # @param id [String] The ID of the conversation to clear
    # @return [Models::Conversation] The updated conversation
    # @raise [Geminize::GeminizeError] If the conversation cannot be loaded or saved
    def clear_conversation(id)
      conversation = get_conversation(id)
      raise Geminize::GeminizeError.new("Conversation not found: #{id}", nil, nil) unless conversation

      conversation.clear
      @repository.save(conversation)
      conversation
    end
  end
end
