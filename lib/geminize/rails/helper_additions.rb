# frozen_string_literal: true

module Geminize
  module Rails
    # Module for adding Geminize view helpers to Rails applications
    # Provides methods to simplify the inclusion of Geminize helpers in views.
    #
    # This module is automatically included in ActionView::Base
    # when the gem is used in a Rails application.
    #
    # @example Using Geminize helpers in a view
    #   <%# After including the helpers in ApplicationHelper %>
    #   <%= render_gemini_conversation %>
    #   <%= gemini_chat_form %>
    module HelperAdditions
      # Add Geminize helpers to views
      # This method includes the GeminizeHelper module in your view context,
      # providing helper methods for rendering Gemini conversations, chat forms,
      # and formatting responses.
      #
      # @return [void]
      # @example
      #   module ApplicationHelper
      #     include Geminize::Rails::HelperAdditions
      #     geminize_helper
      #   end
      def geminize_helper
        include GeminizeHelper
      end
    end
  end
end

# Add our helpers module to ActionView::Base if it exists
ActiveSupport.on_load(:action_view) do
  include Geminize::Rails::HelperAdditions
end
