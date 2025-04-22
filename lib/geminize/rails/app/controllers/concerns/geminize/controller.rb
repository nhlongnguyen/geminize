# frozen_string_literal: true

module Geminize
  # Controller concern for including Gemini functionality in Rails controllers
  module Controller
    extend ActiveSupport::Concern

    included do
      # Helper methods for controllers using Geminize
      helper_method :current_gemini_conversation if respond_to?(:helper_method)
    end

    # Current conversation for this controller context
    # Uses session to maintain conversation state between requests
    # @return [Geminize::Models::Conversation]
    def current_gemini_conversation
      return @current_gemini_conversation if defined?(@current_gemini_conversation)

      if session[:gemini_conversation_id]
        # Try to load existing conversation
        begin
          @current_gemini_conversation = Geminize.load_conversation(session[:gemini_conversation_id])
        rescue => e
          Rails.logger.error("Failed to load Gemini conversation: #{e.message}")
          # Create a new conversation if loading fails
          create_new_gemini_conversation
        end
      else
        # Create a new conversation if one doesn't exist
        create_new_gemini_conversation
      end

      @current_gemini_conversation
    end

    # Send a message in the current conversation
    # @param message [String] The message to send
    # @param model_name [String, nil] Optional model name override
    # @param params [Hash] Additional parameters for the message
    # @return [Geminize::Models::ChatResponse] The response
    def send_gemini_message(message, model_name = nil, params = {})
      response = Geminize.chat(message, current_gemini_conversation, model_name, params)
      Geminize.save_conversation(current_gemini_conversation)
      response
    end

    # Generate text using Gemini
    # @param prompt [String] The prompt to send
    # @param model_name [String, nil] Optional model name override
    # @param params [Hash] Additional parameters for generation
    # @return [Geminize::Models::ContentResponse] The response
    def generate_gemini_text(prompt, model_name = nil, params = {})
      Geminize.generate_text(prompt, model_name, params)
    end

    # Generate text with images using Gemini
    # @param prompt [String] The prompt to send
    # @param images [Array<Hash>] Array of image data
    # @param model_name [String, nil] Optional model name override
    # @param params [Hash] Additional parameters for generation
    # @return [Geminize::Models::ContentResponse] The response
    def generate_gemini_multimodal(prompt, images, model_name = nil, params = {})
      Geminize.generate_multimodal(prompt, images, model_name, params)
    end

    # Generate embeddings for text using Gemini
    # @param text [String, Array<String>] The text to embed
    # @param model_name [String, nil] Optional model name override
    # @param params [Hash] Additional parameters for embedding
    # @return [Geminize::Models::EmbeddingResponse] The embedding response
    def generate_gemini_embedding(text, model_name = nil, params = {})
      Geminize.generate_embedding(text, model_name, params)
    end

    # Start a new conversation and store its ID in the session
    # @param title [String, nil] Optional title for the conversation
    # @return [Geminize::Models::Conversation] The new conversation
    def reset_gemini_conversation(title = nil)
      create_new_gemini_conversation(title)
    end

    private

    # Create a new conversation and store its ID in the session
    # @param title [String, nil] Optional title for the conversation
    # @return [Geminize::Models::Conversation] The new conversation
    def create_new_gemini_conversation(title = nil)
      @current_gemini_conversation = Geminize.create_chat(title)
      session[:gemini_conversation_id] = @current_gemini_conversation.id
      Geminize.save_conversation(@current_gemini_conversation)
      @current_gemini_conversation
    end
  end
end
