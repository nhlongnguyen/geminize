# frozen_string_literal: true

class ChatController < ApplicationController
  # Include Geminize controller functionality
  geminize_controller

  def index
    # Reset conversation if requested
    reset_gemini_conversation("Chat with Gemini") if params[:reset]
  end

  def create
    @response = send_gemini_message(params[:message])

    respond_to do |format|
      format.html { redirect_to chat_path }
      format.turbo_stream
      format.json { render json: {message: @response.text} }
    end
  end

  def reset
    reset_gemini_conversation("New Chat Session")
    redirect_to chat_path, notice: "Started a new conversation"
  end
end
