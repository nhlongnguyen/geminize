# frozen_string_literal: true

require "securerandom"
require "time"
require "json"

module Geminize
  module Models
    # Represents a conversation with message history
    class Conversation
      # @return [String] Unique identifier for the conversation
      attr_reader :id

      # @return [String] Optional title for the conversation
      attr_accessor :title

      # @return [Time] When the conversation was created
      attr_reader :created_at

      # @return [Time] When the conversation was last updated
      attr_reader :updated_at

      # @return [Array<Message>] The messages in the conversation
      attr_reader :messages

      # @return [String, nil] System instruction to guide model behavior
      attr_accessor :system_instruction

      # Initialize a new conversation
      # @param id [String, nil] Unique identifier for the conversation
      # @param title [String, nil] Optional title for the conversation
      # @param messages [Array<Message>, nil] Initial messages
      # @param created_at [Time, nil] When the conversation was created
      # @param system_instruction [String, nil] System instruction to guide model behavior
      def initialize(id = nil, title = nil, messages = nil, created_at = nil, system_instruction = nil)
        @id = id || SecureRandom.uuid
        @title = title
        @messages = messages || []
        @created_at = created_at || Time.now
        @updated_at = @created_at
        @system_instruction = system_instruction
      end

      # Add a user message to the conversation
      # @param content [String] The content of the message
      # @return [UserMessage] The added message
      def add_user_message(content)
        message = UserMessage.new(content)
        add_message(message)
        @updated_at = Time.now
        message
      end

      # Add a model message to the conversation
      # @param content [String] The content of the message
      # @return [ModelMessage] The added message
      def add_model_message(content)
        message = ModelMessage.new(content)
        add_message(message)
        @updated_at = Time.now
        message
      end

      # Add a message to the conversation
      # @param message [Message] The message to add
      # @return [Message] The added message
      def add_message(message)
        @messages << message
        @updated_at = Time.now
        message
      end

      # Get the messages as an array of hashes for the API
      # @return [Array<Hash>] The messages as hashes
      def messages_as_hashes
        @messages.map(&:to_hash)
      end

      # Get the last message in the conversation
      # @return [Message, nil] The last message or nil if there are no messages
      def last_message
        @messages.last
      end

      # Check if the conversation has any messages
      # @return [Boolean] True if the conversation has messages
      def has_messages?
        !@messages.empty?
      end

      # Get the number of messages in the conversation
      # @return [Integer] The number of messages
      def message_count
        @messages.size
      end

      # Clear all messages from the conversation
      # @return [self] The conversation instance
      def clear
        @messages = []
        @updated_at = Time.now
        self
      end

      # Convert the conversation to a hash
      # @return [Hash] The conversation as a hash
      def to_hash
        {
          id: @id,
          title: @title,
          created_at: @created_at.iso8601,
          updated_at: @updated_at.iso8601,
          messages: @messages.map(&:to_hash),
          system_instruction: @system_instruction
        }
      end

      # Alias for to_hash for consistency with Ruby conventions
      # @return [Hash] The conversation as a hash
      def to_h
        to_hash
      end

      # Serialize the conversation to a JSON string
      # @return [String] The conversation as a JSON string
      def to_json(*args)
        to_h.to_json(*args)
      end

      # Create a conversation from a hash
      # @param hash [Hash] The hash to create the conversation from
      # @return [Conversation] A new conversation object
      def self.from_hash(hash)
        id = hash["id"]
        title = hash["title"]
        created_at = hash["created_at"] ? Time.parse(hash["created_at"]) : Time.now
        system_instruction = hash["system_instruction"]

        messages = []
        if hash["messages"]&.is_a?(Array)
          messages = hash["messages"].map { |msg_hash| Message.from_hash(msg_hash) }
        end

        new(id, title, messages, created_at, system_instruction)
      end

      # Create a conversation from a JSON string
      # @param json [String] The JSON string
      # @return [Conversation] A new conversation object
      def self.from_json(json)
        hash = JSON.parse(json)
        from_hash(hash)
      end
    end
  end
end
