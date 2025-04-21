# frozen_string_literal: true

module Geminize
  module Models
    # Base class for messages in a conversation
    class Message
      # @return [String] The content of the message
      attr_reader :content

      # @return [Time] When the message was created
      attr_reader :timestamp

      # @return [String] The role of the message sender (user or model)
      attr_reader :role

      # Initialize a new message
      # @param content [String] The content of the message
      # @param role [String] The role of the message sender
      # @param timestamp [Time, nil] When the message was created
      def initialize(content, role, timestamp = nil)
        @content = content
        @role = role
        @timestamp = timestamp || Time.now
        validate!
      end

      # Convert the message to a hash suitable for the API
      # @return [Hash] The message as a hash
      def to_hash
        {
          role: @role,
          parts: [
            {
              text: @content
            }
          ]
        }
      end

      # Alias for to_hash for consistency with Ruby conventions
      # @return [Hash] The message as a hash
      def to_h
        to_hash
      end

      # Check if this message is from the user
      # @return [Boolean] True if the message is from the user
      def user?
        @role == "user"
      end

      # Check if this message is from the model
      # @return [Boolean] True if the message is from the model
      def model?
        @role == "model"
      end

      # Serialize the message to a JSON string
      # @return [String] The message as a JSON string
      def to_json(*args)
        to_h.to_json(*args)
      end

      # Create a message from a hash
      # @param hash [Hash] The hash to create the message from
      # @return [Message] A new message object
      def self.from_hash(hash)
        content = extract_content(hash)
        role = hash["role"]
        timestamp = hash["timestamp"] ? Time.parse(hash["timestamp"]) : Time.now

        case role
        when "user"
          UserMessage.new(content, timestamp)
        when "model"
          ModelMessage.new(content, timestamp)
        else
          new(content, role, timestamp)
        end
      end

      private

      # Extract content from a message hash
      # @param hash [Hash] The message hash
      # @return [String] The extracted content
      def self.extract_content(hash)
        parts = hash["parts"]
        return "" unless parts && !parts.empty?

        parts.map { |part| part["text"] }.compact.join(" ")
      end

      # Validate the message parameters
      # @raise [Geminize::ValidationError] If any parameter is invalid
      def validate!
        validate_content!
        validate_role!
      end

      # Validate the content parameter
      # @raise [Geminize::ValidationError] If the content is invalid
      def validate_content!
        Validators.validate_not_empty!(@content, "Content")
      end

      # Validate the role parameter
      # @raise [Geminize::ValidationError] If the role is invalid
      def validate_role!
        allowed_roles = ["user", "model", "system"]
        unless allowed_roles.include?(@role)
          raise Geminize::ValidationError.new(
            "Role must be one of: #{allowed_roles.join(', ')}",
            "INVALID_ARGUMENT"
          )
        end
      end
    end

    # Represents a message from the user
    class UserMessage < Message
      # Initialize a new user message
      # @param content [String] The content of the message
      # @param timestamp [Time, nil] When the message was created
      def initialize(content, timestamp = nil)
        super(content, "user", timestamp)
      end
    end

    # Represents a message from the model
    class ModelMessage < Message
      # Initialize a new model message
      # @param content [String] The content of the message
      # @param timestamp [Time, nil] When the message was created
      def initialize(content, timestamp = nil)
        super(content, "model", timestamp)
      end
    end
  end
end
