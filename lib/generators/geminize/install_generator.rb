# frozen_string_literal: true

require "rails/generators/base"

module Geminize
  module Generators
    # Generator for installing Geminize Rails integration
    # This generator creates an initializer with default configuration
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates a Geminize initializer for Rails."

      def create_initializer_file
        template "initializer.rb", "config/initializers/geminize.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
