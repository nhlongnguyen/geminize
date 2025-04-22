# frozen_string_literal: true

module Geminize
  module Rails
    # Rails engine for Geminize
    # Provides Rails integration for the Gemini API.
    class Engine < ::Rails::Engine
      isolate_namespace Geminize

      initializer "geminize.configure" do |app|
        # Set up configuration if needed
      end

      initializer "geminize.load_concerns" do
        ActiveSupport.on_load(:action_controller) do
          require "geminize/rails/app/controllers/concerns/geminize/controller"
        end

        ActiveSupport.on_load(:action_view) do
          require "geminize/rails/app/helpers/geminize_helper"
        end
      end

      config.to_prepare do
        # Load any dependencies that need to be available
      end
    end
  end
end
