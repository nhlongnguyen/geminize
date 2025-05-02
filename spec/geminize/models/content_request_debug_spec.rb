# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Models::ContentRequest do
  describe "debug to_hash" do
    let(:prompt) { "What's the weather in New York?" }
    let(:model_name) { "gemini-1.5-pro" }
    let(:params) { { temperature: 0.7 } }

    it "inspects the original to_hash method" do
      request = described_class.new(prompt, model_name, params)

      # Print out the hash structure
      puts "\nOriginal hash structure:"
      pp request.to_hash

      # Add a function and see what happens
      puts "\nHash structure after adding a function:"
      request.add_function(
        "get_weather",
        "Get weather",
        { type: "object" }
      )
      pp request.to_hash

      # Test if tools exist in the hash
      hash = request.to_hash
      puts "\nDoes hash have tools? #{hash.key?(:tools)}"
      puts "Tools: #{hash[:tools].inspect}" if hash.key?(:tools)

      expect(true).to be true # Dummy expectation
    end
  end
end
