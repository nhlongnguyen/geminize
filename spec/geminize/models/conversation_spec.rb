# frozen_string_literal: true

RSpec.describe Geminize::Models::Conversation do
  let(:id) { "test-id" }
  let(:title) { "Test Conversation" }
  let(:created_at) { Time.now }
  let(:conversation) { described_class.new(id, title, nil, created_at) }

  describe "#initialize" do
    it "initializes with provided values" do
      expect(conversation.id).to eq(id)
      expect(conversation.title).to eq(title)
      expect(conversation.messages).to eq([])
      expect(conversation.created_at).to eq(created_at)
      expect(conversation.updated_at).to eq(created_at)
    end

    it "generates a UUID if no id is provided" do
      allow(SecureRandom).to receive(:uuid).and_return("generated-uuid")
      conversation = described_class.new
      expect(conversation.id).to eq("generated-uuid")
    end

    it "sets created_at to current time if not provided" do
      frozen_time = Time.now
      allow(Time).to receive(:now).and_return(frozen_time)
      conversation = described_class.new
      expect(conversation.created_at).to eq(frozen_time)
    end
  end

  describe "#add_user_message" do
    it "adds a user message to the conversation" do
      expect {
        conversation.add_user_message("Hello")
      }.to change { conversation.message_count }.by(1)

      message = conversation.messages.last
      expect(message).to be_a(Geminize::Models::UserMessage)
      expect(message.content).to eq("Hello")
    end

    it "updates the updated_at timestamp" do
      old_time = conversation.updated_at

      # Ensure time difference
      allow(Time).to receive(:now).and_return(old_time + 60)

      conversation.add_user_message("Hello")
      expect(conversation.updated_at).to be > old_time
    end
  end

  describe "#add_model_message" do
    it "adds a model message to the conversation" do
      expect {
        conversation.add_model_message("Hello back")
      }.to change { conversation.message_count }.by(1)

      message = conversation.messages.last
      expect(message).to be_a(Geminize::Models::ModelMessage)
      expect(message.content).to eq("Hello back")
    end
  end

  describe "#messages_as_hashes" do
    before do
      conversation.add_user_message("User message")
      conversation.add_model_message("Model message")
    end

    it "returns all messages as hashes" do
      hashes = conversation.messages_as_hashes
      expect(hashes.size).to eq(2)
      expect(hashes[0][:role]).to eq("user")
      expect(hashes[0][:parts][0][:text]).to eq("User message")
      expect(hashes[1][:role]).to eq("model")
      expect(hashes[1][:parts][0][:text]).to eq("Model message")
    end
  end

  describe "#last_message" do
    it "returns nil when there are no messages" do
      expect(conversation.last_message).to be_nil
    end

    it "returns the last message when there are messages" do
      conversation.add_user_message("First")
      conversation.add_model_message("Last")
      expect(conversation.last_message.content).to eq("Last")
    end
  end

  describe "#has_messages?" do
    it "returns false when there are no messages" do
      expect(conversation.has_messages?).to be false
    end

    it "returns true when there are messages" do
      conversation.add_user_message("Hello")
      expect(conversation.has_messages?).to be true
    end
  end

  describe "#message_count" do
    it "returns 0 when there are no messages" do
      expect(conversation.message_count).to eq(0)
    end

    it "returns the correct count when there are messages" do
      conversation.add_user_message("One")
      conversation.add_user_message("Two")
      expect(conversation.message_count).to eq(2)
    end
  end

  describe "#clear" do
    before do
      conversation.add_user_message("One")
      conversation.add_model_message("Two")
    end

    it "removes all messages" do
      expect {
        conversation.clear
      }.to change { conversation.message_count }.from(2).to(0)
    end

    it "updates the updated_at timestamp" do
      old_time = conversation.updated_at

      # Ensure time difference
      allow(Time).to receive(:now).and_return(old_time + 60)

      conversation.clear
      expect(conversation.updated_at).to be > old_time
    end
  end

  describe "#to_hash" do
    let(:created_time) { Time.parse("2023-01-01T00:00:00Z") }
    let(:updated_time) { Time.parse("2023-01-01T01:00:00Z") }

    it "returns a hash representation of the conversation" do
      conversation = described_class.new(id, title, nil, created_time)

      # Mock Time.now to return our expected updated_time
      allow(Time).to receive(:now).and_return(updated_time)

      # Add a message (this will now set updated_at to our mocked time)
      conversation.add_user_message("Hello")

      # Get the hash representation
      hash = conversation.to_hash

      expect(hash[:id]).to eq(id)
      expect(hash[:title]).to eq(title)
      expect(hash[:created_at]).to eq("2023-01-01T00:00:00Z")
      expect(hash[:updated_at]).to eq("2023-01-01T01:00:00Z")
      expect(hash[:messages]).to be_an(Array)
      expect(hash[:messages].size).to eq(1)
    end
  end

  describe ".from_hash" do
    let(:hash) do
      {
        "id" => "conv-123",
        "title" => "Test Conversation",
        "created_at" => "2023-01-01T00:00:00Z",
        "updated_at" => "2023-01-01T01:00:00Z",
        "messages" => [
          {
            "role" => "user",
            "parts" => [{"text" => "Hello"}]
          }
        ]
      }
    end

    it "creates a conversation from a hash" do
      allow(Geminize::Models::Message).to receive(:from_hash).and_return(
        Geminize::Models::UserMessage.new("Hello")
      )

      conversation = described_class.from_hash(hash)
      expect(conversation.id).to eq("conv-123")
      expect(conversation.title).to eq("Test Conversation")
      expect(conversation.created_at).to be_a(Time)
      expect(conversation.message_count).to eq(1)
    end
  end

  describe ".from_json" do
    let(:json) { '{"id":"json-id","title":"JSON Title","messages":[]}' }

    it "parses JSON and creates a conversation" do
      hash = {"id" => "json-id", "title" => "JSON Title", "messages" => []}
      allow(JSON).to receive(:parse).with(json).and_return(hash)
      allow(described_class).to receive(:from_hash).with(hash).and_return("conversation")

      expect(described_class.from_json(json)).to eq("conversation")
    end
  end
end
