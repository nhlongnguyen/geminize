# frozen_string_literal: true

module Geminize
  # Class for chat functionality
  class Chat
    # @return [Geminize::Client] The client instance
    attr_reader :client

    # @return [Models::Conversation] The current conversation
    attr_reader :conversation

    # Initialize a new chat instance
    # @param conversation [Geminize::Models::Conversation, nil] The conversation to use
    # @param client [Geminize::Client, nil] The client to use (optional)
    # @param options [Hash] Additional options
    def initialize(conversation = nil, client = nil, options = {})
      @conversation = conversation || Models::Conversation.new
      @client = client || Client.new(options)
      @options = options
    end

    # Send a user message and get a model response
    # @param content [String] The content of the user message
    # @param model_name [String, nil] The model to use (optional)
    # @param params [Hash] Additional generation parameters
    # @option params [Float] :temperature Controls randomness (0.0-1.0)
    # @option params [Integer] :max_tokens Maximum tokens to generate
    # @option params [Float] :top_p Top-p value for nucleus sampling (0.0-1.0)
    # @option params [Integer] :top_k Top-k value for sampling
    # @option params [Array<String>] :stop_sequences Stop sequences to end generation
    # @return [Models::ChatResponse] The chat response
    # @raise [Geminize::GeminizeError] If the request fails
    def send_message(content, model_name = nil, params = {})
      # Add user message to conversation
      @conversation.add_user_message(content)

      # Create the chat request
      chat_request = Models::ChatRequest.new(
        content,
        model_name || Geminize.configuration.default_model,
        nil, # user_id
        params
      )

      # Generate the response using the conversation history
      response = generate_response(chat_request)

      # Extract and add the model's response to the conversation
      if response.has_text?
        @conversation.add_model_message(response.text)
      end

      response
    end

    # Generate a response based on the current conversation
    # @param chat_request [Models::ChatRequest] The chat request
    # @return [Models::ChatResponse] The chat response
    # @raise [Geminize::GeminizeError] If the request fails
    def generate_response(chat_request)
      model_name = chat_request.model_name
      endpoint = RequestBuilder.build_text_generation_endpoint(model_name)

      # Create payload with conversation history
      payload = RequestBuilder.build_chat_request(chat_request, @conversation.messages_as_hashes)

      # Send request to API
      response_data = @client.post(endpoint, payload)
      Models::ChatResponse.from_hash(response_data)
    end

    # Create a new conversation
    # @param title [String, nil] Optional title for the conversation
    # @return [Chat] A new chat instance with a fresh conversation
    def self.new_conversation(title = nil)
      conversation = Models::Conversation.new(nil, title)
      new(conversation)
    end
  end
end
