# frozen_string_literal: true

module Geminize
  # Railtie for lightweight Rails integration
  # Provides basic Rails integration when the full engine is not required.
  # This is automatically loaded when the gem is used in a Rails application.
  #
  # @example Basic usage in a Rails application
  #   # No additional setup needed - Railtie is loaded automatically
  #   # In your controller:
  #   class ExamplesController < ApplicationController
  #     def example
  #       @response = Geminize.generate_text("What is Ruby on Rails?").text
  #     end
  #   end
  class Railtie < ::Rails::Railtie
    # Configure Geminize when used in a Rails application
    # @return [void]
    initializer "geminize.configure" do |app|
      # Set up configuration for Geminize when used in a Rails app
      Geminize.configure do |config|
        # Set conversations path to Rails tmp directory by default
        config.conversations_path = Rails.root.join("tmp", "conversations") if config.conversations_path.nil?
      end
    end

    # Set up any rake tasks if needed
    # @return [void]
    rake_tasks do
      # Define rake tasks here if needed
    end
  end
end
