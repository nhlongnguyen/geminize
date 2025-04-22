# frozen_string_literal: true

require "geminize/rails/engine" if defined?(::Rails::Engine)
require "geminize/railtie" if defined?(::Rails::Railtie)
require "geminize/rails/controller_additions" if defined?(::ActionController::Base)
require "geminize/rails/helper_additions" if defined?(::ActionView::Base)

module Geminize
  # Rails integration module for Geminize
  # Provides Rails integration for the Google Gemini API.
  #
  # The integration includes:
  # - A Rails engine to load all required components
  # - Controller concerns with helper methods for Gemini operations
  # - View helpers for rendering conversations and responses
  # - Generators for creating configuration files
  #
  # @example Setting up in a Rails application
  #   # In config/initializers/geminize.rb (created by the generator)
  #   Geminize.configure do |config|
  #     config.api_key = ENV.fetch("GEMINI_API_KEY")
  #   end
  #
  #   # In app/controllers/chat_controller.rb
  #   class ChatController < ApplicationController
  #     geminize_controller
  #
  #     def create
  #       @response = send_gemini_message(params[:message])
  #       redirect_to chat_path
  #     end
  #   end
  #
  #   # In app/views/chat/show.html.erb
  #   <%= render_gemini_conversation %>
  #   <%= gemini_chat_form %>
  module Rails
    # Returns true if running in a Rails environment
    # Useful for conditionally executing code only in Rails apps.
    #
    # @return [Boolean] true if Rails is defined
    # @example
    #   if Geminize::Rails.rails?
    #     # Rails-specific code
    #   end
    def self.rails?
      defined?(::Rails)
    end
  end
end
