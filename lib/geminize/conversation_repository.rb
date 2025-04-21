# frozen_string_literal: true

require "fileutils"
require "json"

module Geminize
  # Interface for conversation repositories
  class ConversationRepository
    # Save a conversation
    # @param conversation [Models::Conversation] The conversation to save
    # @return [Boolean] True if the save was successful
    def save(conversation)
      raise NotImplementedError, "Subclasses must implement #save"
    end

    # Load a conversation by ID
    # @param id [String] The ID of the conversation to load
    # @return [Models::Conversation, nil] The loaded conversation or nil if not found
    def load(id)
      raise NotImplementedError, "Subclasses must implement #load"
    end

    # Delete a conversation by ID
    # @param id [String] The ID of the conversation to delete
    # @return [Boolean] True if the deletion was successful
    def delete(id)
      raise NotImplementedError, "Subclasses must implement #delete"
    end

    # List all available conversations
    # @return [Array<Hash>] An array of conversation metadata
    def list
      raise NotImplementedError, "Subclasses must implement #list"
    end
  end

  # File-based implementation of the ConversationRepository
  class FileConversationRepository < ConversationRepository
    # @return [String] The directory where conversations are stored
    attr_reader :storage_dir

    # Initialize a new file-based repository
    # @param directory [String] The directory to store conversations in
    def initialize(directory = nil)
      @storage_dir = directory || File.join(Dir.home, ".geminize", "conversations")
      FileUtils.mkdir_p(@storage_dir) unless Dir.exist?(@storage_dir)
    end

    # Save a conversation to disk
    # @param conversation [Models::Conversation] The conversation to save
    # @return [Boolean] True if the save was successful
    def save(conversation)
      return false unless conversation

      begin
        file_path = file_path_for(conversation.id)
        File.write(file_path, conversation.to_json)
        true
      rescue
        false
      end
    end

    # Load a conversation from disk by ID
    # @param id [String] The ID of the conversation to load
    # @return [Models::Conversation, nil] The loaded conversation or nil if not found
    def load(id)
      file_path = file_path_for(id)
      return nil unless File.exist?(file_path)

      begin
        json = File.read(file_path)
        Models::Conversation.from_json(json)
      rescue
        nil
      end
    end

    # Delete a conversation from disk by ID
    # @param id [String] The ID of the conversation to delete
    # @return [Boolean] True if the deletion was successful
    def delete(id)
      file_path = file_path_for(id)
      return false unless File.exist?(file_path)

      begin
        File.delete(file_path)
        true
      rescue
        false
      end
    end

    # List all available conversations
    # @return [Array<Models::Conversation>] An array of conversations
    def list
      Dir.glob(File.join(@storage_dir, "*.json")).map do |file_path|
        json = File.read(file_path)
        Models::Conversation.from_json(json)
      rescue
        nil # Skip files that can't be parsed
      end.compact.sort_by { |conversation| conversation.updated_at }.reverse
    rescue
      []
    end

    private

    # Get the file path for a conversation ID
    # @param id [String] The conversation ID
    # @return [String] The file path
    def file_path_for(id)
      # Ensure the ID is safe for a filename
      safe_id = id.to_s.gsub(/[^a-zA-Z0-9_-]/, "_")
      File.join(@storage_dir, "#{safe_id}.json")
    end
  end

  # In-memory implementation of the ConversationRepository (for testing)
  class MemoryConversationRepository < ConversationRepository
    # Initialize a new memory repository
    def initialize
      @conversations = {}
    end

    # Save a conversation to memory
    # @param conversation [Models::Conversation] The conversation to save
    # @return [Boolean] True if the save was successful
    def save(conversation)
      return false unless conversation

      @conversations[conversation.id] = conversation
      true
    end

    # Load a conversation from memory by ID
    # @param id [String] The ID of the conversation to load
    # @return [Models::Conversation, nil] The loaded conversation or nil if not found
    def load(id)
      @conversations[id]
    end

    # Delete a conversation from memory by ID
    # @param id [String] The ID of the conversation to delete
    # @return [Boolean] True if the deletion was successful
    def delete(id)
      if @conversations.key?(id)
        @conversations.delete(id)
        true
      else
        false
      end
    end

    # List all available conversations
    # @return [Array<Models::Conversation>] An array of conversations
    def list
      @conversations.values.sort_by(&:updated_at).reverse
    end
  end
end
