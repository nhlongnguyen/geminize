# frozen_string_literal: true

require_relative "lib/geminize/version"

Gem::Specification.new do |spec|
  spec.name = "geminize"
  spec.version = Geminize::VERSION
  spec.authors = ["Nhat Long Nguyen"]
  spec.email = ["nhatlongnguyen1992@gmail.com"]

  spec.summary = "Ruby interface for Google's Gemini AI API"
  spec.description = "A convenient and robust Ruby interface for the Google Gemini API, enabling easy integration of powerful generative AI models into your applications. Includes support for text generation, chat conversations, embeddings, multimodal content, and Rails integration."
  spec.homepage = "https://github.com/nhlongnguyen/geminize"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nhlongnguyen/geminize"
  spec.metadata["changelog_uri"] = "https://github.com/nhlongnguyen/geminize/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Add Faraday for HTTP client
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  # Add mime-types for MIME type detection
  spec.add_dependency "mime-types", "~> 3.5"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.14"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
