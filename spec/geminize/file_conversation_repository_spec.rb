# frozen_string_literal: true

require "tmpdir"
require "securerandom"

RSpec.describe Geminize::FileConversationRepository do
  let(:storage_dir) { File.join(Dir.tmpdir, "geminize_test_#{SecureRandom.hex(8)}") }
  let(:repository) { described_class.new(storage_dir) }
  let(:conversation) { Geminize::Models::Conversation.new("conv-123", "Test Conversation") }

  before do
    FileUtils.mkdir_p(storage_dir)
  end

  after do
    FileUtils.rm_rf(storage_dir) if Dir.exist?(storage_dir)
  end

  describe "#initialize" do
    it "creates the storage directory if it doesn't exist" do
      non_existent_dir = File.join(Dir.tmpdir, "non_existent_#{SecureRandom.hex(8)}")
      expect(Dir.exist?(non_existent_dir)).to be false

      described_class.new(non_existent_dir)
      expect(Dir.exist?(non_existent_dir)).to be true

      FileUtils.rm_rf(non_existent_dir)
    end

    it "uses the default directory if none is provided" do
      allow(Dir).to receive(:home).and_return("/home/test")
      allow(FileUtils).to receive(:mkdir_p)
      repo = described_class.new
      expect(repo.storage_dir).to eq(File.join("/home/test", ".geminize", "conversations"))
    end
  end

  describe "#save" do
    it "saves a conversation to a file" do
      expect(repository.save(conversation)).to be true

      file_path = File.join(storage_dir, "#{conversation.id}.json")
      expect(File.exist?(file_path)).to be true

      json_content = File.read(file_path)
      saved_data = JSON.parse(json_content)
      expect(saved_data["id"]).to eq(conversation.id)
      expect(saved_data["title"]).to eq(conversation.title)
    end

    it "returns false if the conversation is nil" do
      expect(repository.save(nil)).to be false
    end

    it "handles IO errors gracefully" do
      allow(File).to receive(:write).and_raise(IOError.new("Test IO error"))
      expect(repository.save(conversation)).to be false
    end
  end

  describe "#load" do
    context "when conversation exists" do
      before do
        repository.save(conversation)
      end

      it "loads a conversation from a file" do
        loaded_conversation = repository.load(conversation.id)
        expect(loaded_conversation).not_to be_nil
        expect(loaded_conversation.id).to eq(conversation.id)
        expect(loaded_conversation.title).to eq(conversation.title)
      end
    end

    context "when conversation doesn't exist" do
      it "returns nil" do
        expect(repository.load("non-existent")).to be_nil
      end
    end

    it "handles IO errors gracefully" do
      allow(File).to receive(:read).and_raise(IOError.new("Test IO error"))
      expect(repository.load("any-id")).to be_nil
    end

    it "handles JSON parsing errors gracefully" do
      file_path = File.join(storage_dir, "invalid.json")
      File.write(file_path, "invalid json")

      expect(repository.load("invalid")).to be_nil
    end
  end

  describe "#list" do
    before do
      3.times do |i|
        conv = Geminize::Models::Conversation.new("conv-#{i}", "Conversation #{i}")
        repository.save(conv)
      end
    end

    it "lists all saved conversations" do
      conversations = repository.list
      expect(conversations.size).to eq(3)

      # Verify conversations are included in the list
      ids = conversations.map(&:id)
      titles = conversations.map(&:title)
      expect(ids).to include("conv-0", "conv-1", "conv-2")
      expect(titles).to include("Conversation 0", "Conversation 1", "Conversation 2")
    end

    it "returns an empty array if no conversations exist" do
      FileUtils.rm_rf(storage_dir)
      FileUtils.mkdir_p(storage_dir)

      expect(repository.list).to eq([])
    end

    it "handles IO errors gracefully" do
      allow(Dir).to receive(:glob).and_raise(IOError.new("Test IO error"))
      expect(repository.list).to eq([])
    end

    it "ignores files that can't be loaded" do
      # Create an invalid JSON file
      File.write(File.join(storage_dir, "invalid.json"), "invalid json")

      # Should still load the valid conversations
      conversations = repository.list
      expect(conversations.size).to eq(3)  # Still loads the 3 valid ones
    end
  end

  describe "#delete" do
    before do
      repository.save(conversation)
    end

    it "deletes a conversation file" do
      file_path = File.join(storage_dir, "#{conversation.id}.json")
      expect(File.exist?(file_path)).to be true

      expect(repository.delete(conversation.id)).to be true
      expect(File.exist?(file_path)).to be false
    end

    it "returns false if the conversation doesn't exist" do
      expect(repository.delete("non-existent")).to be false
    end

    it "handles IO errors gracefully" do
      allow(File).to receive(:delete).and_raise(IOError.new("Test IO error"))
      expect(repository.delete(conversation.id)).to be false
    end
  end
end
