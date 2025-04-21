# frozen_string_literal: true

RSpec.describe Geminize::Models::Memory do
  let(:role) { "user" }
  let(:parts) { [{text: "Hello, world!"}] }
  let(:memory) { described_class.new(role, parts) }

  describe "#initialize" do
    it "sets the role and parts" do
      expect(memory.role).to eq(role)
      expect(memory.parts).to eq(parts)
    end

    it "defaults to parts with empty string if none provided" do
      memory = described_class.new(role)
      expect(memory.parts).to eq([{text: ""}])
    end

    it "defaults to empty string for role if none provided" do
      memory = described_class.new
      expect(memory.role).to eq("")
    end

    it "makes parts immutable" do
      expect { memory.parts << {text: "another part"} }.to raise_error(FrozenError)
    end
  end

  describe "#to_h" do
    it "returns a hash with role and parts" do
      expect(memory.to_h).to eq({
        role: role,
        parts: parts
      })
    end
  end

  describe "#to_json" do
    it "returns a JSON string representation" do
      json = memory.to_json
      parsed = JSON.parse(json)

      expect(parsed["role"]).to eq(role)
      expect(parsed["parts"]).to be_an(Array)
      expect(parsed["parts"].first["text"]).to eq("Hello, world!")
    end

    it "accepts JSON generate options" do
      json_pretty = memory.to_json(pretty: true)
      expect(json_pretty).to include("\n")
    end
  end

  describe ".from_hash" do
    let(:hash) { {role: "user", parts: [{text: "Test message"}]} }

    it "creates a Memory object from a hash" do
      memory = described_class.from_hash(hash)
      expect(memory).to be_a(described_class)
      expect(memory.role).to eq("user")
      expect(memory.parts).to eq([{text: "Test message"}])
    end

    it "creates a Memory object from a hash with string keys" do
      hash_with_string_keys = {"role" => "user", "parts" => [{"text" => "Test message"}]}
      memory = described_class.from_hash(hash_with_string_keys)

      expect(memory).to be_a(described_class)
      expect(memory.role).to eq("user")
      expect(memory.parts).to eq([{text: "Test message"}])
    end

    it "handles missing parts" do
      hash_without_parts = {role: "user"}
      memory = described_class.from_hash(hash_without_parts)

      expect(memory.parts).to eq([{text: ""}])
    end

    it "handles missing role" do
      hash_without_role = {parts: [{text: "Test message"}]}
      memory = described_class.from_hash(hash_without_role)

      expect(memory.role).to eq("")
    end
  end

  describe ".from_json" do
    let(:json_string) { '{"role":"user","parts":[{"text":"Test message"}]}' }

    it "creates a Memory object from a JSON string" do
      memory = described_class.from_json(json_string)

      expect(memory).to be_a(described_class)
      expect(memory.role).to eq("user")
      expect(memory.parts).to eq([{text: "Test message"}])
    end

    it "handles invalid JSON" do
      expect { described_class.from_json("invalid json") }.to raise_error(JSON::ParserError)
    end
  end

  describe "#==" do
    it "returns true for identical memories" do
      memory1 = described_class.new("user", [{text: "Hello"}])
      memory2 = described_class.new("user", [{text: "Hello"}])

      expect(memory1).to eq(memory2)
    end

    it "returns false for memories with different roles" do
      memory1 = described_class.new("user", [{text: "Hello"}])
      memory2 = described_class.new("assistant", [{text: "Hello"}])

      expect(memory1).not_to eq(memory2)
    end

    it "returns false for memories with different parts" do
      memory1 = described_class.new("user", [{text: "Hello"}])
      memory2 = described_class.new("user", [{text: "Goodbye"}])

      expect(memory1).not_to eq(memory2)
    end

    it "returns false when compared with a different object type" do
      memory = described_class.new("user", [{text: "Hello"}])

      expect(memory).not_to eq("not a memory")
    end
  end
end
