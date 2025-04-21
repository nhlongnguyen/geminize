# frozen_string_literal: true

require "json"

module Geminize
  module Models
    # Represents a message in the Gemini format
    class Memory
      # @return [String] The role of the sender (user, model, system)
      attr_reader :role

      # @return [Array<Hash>] The parts of the message (e.g., text content)
      attr_reader :parts

      # Initialize a new memory
      # @param role [String] The role of the sender (user, model, system)
      # @param parts [Array<Hash>] The parts of the message
      def initialize(role = "", parts = nil)
        @role = role
        @parts = parts || [{text: ""}]
        @parts.freeze
      end

      # Convert the memory to a hash suitable for API requests
      # @return [Hash] The memory as a hash
      def to_h
        {
          role: @role,
          parts: @parts
        }
      end

      # Convert the memory to a JSON string
      # @param opts [Hash] JSON generate options
      # @return [String] The memory as a JSON string
      def to_json(*opts)
        if opts.first && opts.first[:pretty]
          JSON.pretty_generate(to_h)
        else
          to_h.to_json(*opts)
        end
      end

      # Equality comparison
      # @param other [Object] The object to compare with
      # @return [Boolean] True if the objects are equal
      def ==(other)
        return false unless other.is_a?(Memory)
        role == other.role && parts == other.parts
      end

      # Create a Memory object from a hash
      # @param hash [Hash] The hash to create from
      # @return [Memory] A new Memory object
      def self.from_hash(hash)
        # Handle both string and symbol keys
        role = hash[:role] || hash["role"] || ""

        # Handle parts
        parts_data = hash[:parts] || hash["parts"]
        parts = if parts_data
          # Convert string keys to symbols
          parts_data.map do |part|
            if part.is_a?(Hash)
              part_with_symbol_keys = {}
              part.each { |k, v| part_with_symbol_keys[k.to_sym] = v }
              part_with_symbol_keys
            else
              part
            end
          end
        else
          [{text: ""}]
        end

        new(role, parts)
      end

      # Create a Memory object from a JSON string
      # @param json [String] The JSON string
      # @return [Memory] A new Memory object
      def self.from_json(json)
        hash = JSON.parse(json)
        from_hash(hash)
      end
    end
  end
end
