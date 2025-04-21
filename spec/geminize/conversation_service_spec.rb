# frozen_string_literal: true

RSpec.describe Geminize::ConversationService do
  let(:repository) { instance_double(Geminize::ConversationRepository) }
  let(:client) { instance_double(Geminize::Client) }
  let(:service) { described_class.new(repository, client) }
  let(:conversation) { instance_double(Geminize::Models::Conversation, id: "conv-123", title: "Test Conversation") }
  let(:chat) { instance_double(Geminize::Chat) }
  let(:chat_response) { instance_double(Geminize::Models::ChatResponse) }

  describe "#initialize" do
    it "initializes with repository and client" do
      expect(service.repository).to eq(repository)
      expect(service.client).to eq(client)
    end

    it "uses default repository if none provided" do
      allow(Geminize).to receive(:conversation_repository).and_return("default_repo")
      service = described_class.new(nil, client)
      expect(service.repository).to eq("default_repo")
    end

    it "creates a new client if none provided" do
      allow(Geminize::Client).to receive(:new).and_return("new_client")
      service = described_class.new(repository)
      expect(service.client).to eq("new_client")
    end
  end

  describe "#create_conversation" do
    it "creates a new conversation with the given title" do
      allow(Geminize::Models::Conversation).to receive(:new).with(nil, "New Conversation")
        .and_return(conversation)
      allow(repository).to receive(:save).with(conversation).and_return(true)

      result = service.create_conversation("New Conversation")
      expect(result).to eq(conversation)
    end
  end

  describe "#get_conversation" do
    context "when conversation exists" do
      it "returns the conversation from the repository" do
        allow(repository).to receive(:load).with("conv-123").and_return(conversation)
        expect(service.get_conversation("conv-123")).to eq(conversation)
      end
    end

    context "when conversation doesn't exist" do
      it "returns nil" do
        allow(repository).to receive(:load).with("non-existent").and_return(nil)
        expect(service.get_conversation("non-existent")).to be_nil
      end
    end
  end

  describe "#send_message" do
    before do
      allow(repository).to receive(:load).with("conv-123").and_return(conversation)
      allow(Geminize::Chat).to receive(:new).with(conversation, client, {}).and_return(chat)
      allow(chat).to receive(:send_message).with("Hello", nil, {}).and_return(chat_response)
      allow(repository).to receive(:save).with(conversation).and_return(true)
    end

    it "sends a message to the conversation and returns the response and updated conversation" do
      result = service.send_message("conv-123", "Hello")
      expect(result).to be_a(Hash)
      expect(result[:response]).to eq(chat_response)
      expect(result[:conversation]).to eq(conversation)
    end

    it "forwards optional parameters to send_message" do
      allow(chat).to receive(:send_message).with("Hello", "gemini-pro", {temperature: 0.7})
        .and_return(chat_response)

      service.send_message("conv-123", "Hello", "gemini-pro", {temperature: 0.7})
    end

    it "raises an error if conversation not found" do
      allow(repository).to receive(:load).with("non-existent").and_return(nil)
      expect { service.send_message("non-existent", "Hello") }
        .to raise_error(Geminize::GeminizeError, "Conversation not found: non-existent")
    end
  end

  describe "#list_conversations" do
    it "delegates to the repository" do
      allow(repository).to receive(:list).and_return(["conversation1", "conversation2"])
      expect(service.list_conversations).to eq(["conversation1", "conversation2"])
    end
  end

  describe "#delete_conversation" do
    it "delegates to the repository" do
      allow(repository).to receive(:delete).with("conv-123").and_return(true)
      expect(service.delete_conversation("conv-123")).to eq(true)
    end
  end

  describe "#update_conversation_title" do
    it "updates the conversation title and saves it" do
      allow(repository).to receive(:load).with("conv-123").and_return(conversation)
      allow(conversation).to receive(:title=).with("New Title")
      allow(repository).to receive(:save).with(conversation).and_return(true)

      result = service.update_conversation_title("conv-123", "New Title")
      expect(result).to eq(conversation)
    end

    it "raises an error if conversation not found" do
      allow(repository).to receive(:load).with("non-existent").and_return(nil)
      expect { service.update_conversation_title("non-existent", "New Title") }
        .to raise_error(Geminize::GeminizeError, "Conversation not found: non-existent")
    end
  end

  describe "#clear_conversation" do
    it "clears the conversation messages and saves it" do
      allow(repository).to receive(:load).with("conv-123").and_return(conversation)
      allow(conversation).to receive(:clear).and_return(conversation)
      allow(repository).to receive(:save).with(conversation).and_return(true)

      result = service.clear_conversation("conv-123")
      expect(result).to eq(conversation)
    end

    it "raises an error if conversation not found" do
      allow(repository).to receive(:load).with("non-existent").and_return(nil)
      expect { service.clear_conversation("non-existent") }
        .to raise_error(Geminize::GeminizeError, "Conversation not found: non-existent")
    end
  end
end
