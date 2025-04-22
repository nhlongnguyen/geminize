# frozen_string_literal: true

module Geminize
  module Rails
    # Module for adding Geminize functionality to controllers
    # Provides methods that make it easy to include Geminize controller concerns.
    #
    # This module is automatically included in ActionController::Base
    # when the gem is used in a Rails application.
    #
    # @example Including in a specific controller
    #   class ChatController < ApplicationController
    #     geminize_controller
    #
    #     def create
    #       @response = send_gemini_message(params[:message])
    #       render :show
    #     end
    #   end
    module ControllerAdditions
      # Add Geminize functionality to a controller
      # This method includes the Geminize::Controller concern in your controller,
      # which provides methods for working with the Gemini API.
      #
      # @return [void]
      # @example
      #   class ApplicationController < ActionController::Base
      #     include Geminize::Rails::ControllerAdditions
      #     geminize_controller
      #   end
      def geminize_controller
        include Geminize::Controller
      end
    end
  end
end

# Add the module to ActionController::Base if it exists
ActiveSupport.on_load(:action_controller) do
  include Geminize::Rails::ControllerAdditions
end
