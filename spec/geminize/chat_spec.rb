# frozen_string_literal: true

RSpec.describe Geminize::Chat do
  let(:client) { instance_double(Geminize::Client) }
  let(:conversation) { Geminize::Models::Conversation.new }
  let(:chat) { described_class.new(conversation, client) }

  describe "#initialize" do
    it "initializes with a conversation and client" do
      expect(chat.conversation).to eq(conversation)
      expect(chat.client).to eq(client)
    end

    it "creates a new conversation if none is provided" do
      chat = described_class.new(nil, client)
      expect(chat.conversation).to be_a(Geminize::Models::Conversation)
    end

    it "creates a new client if none is provided" do
      allow(Geminize::Client).to receive(:new).and_return(client)
      chat = described_class.new(conversation)
      expect(chat.client).to eq(client)
    end
  end

  describe "#send_message" do
    let(:message) { "Hello, how are you?" }
    let(:model_name) { "gemini-1.5-pro-latest" }
    let(:chat_request) { instance_double(Geminize::Models::ChatRequest, model_name: model_name) }
    let(:chat_response) { instance_double(Geminize::Models::ChatResponse, has_text?: true, text: "I'm doing well, thank you!") }

    before do
      allow(Geminize::Models::ChatRequest).to receive(:new).and_return(chat_request)
      allow(chat).to receive(:generate_response).and_return(chat_response)
      allow(conversation).to receive(:add_user_message).and_return(nil)
      allow(conversation).to receive(:add_model_message).and_return(nil)
      allow(conversation).to receive(:system_instruction).and_return(nil)
    end

    it "adds the user message to the conversation" do
      expect(conversation).to receive(:add_user_message).with(message)
      chat.send_message(message, model_name)
    end

    it "creates a chat request with the message" do
      expect(Geminize::Models::ChatRequest).to receive(:new).with(message, model_name, nil, {})
      chat.send_message(message, model_name)
    end

    context "when system instruction is provided" do
      let(:system_instruction) { "You are a helpful assistant" }

      it "creates a chat request with system instruction" do
        expect(Geminize::Models::ChatRequest).to receive(:new).with(
          message, model_name, nil, {system_instruction: system_instruction}
        )
        chat.send_message(message, model_name, system_instruction: system_instruction)
      end
    end

    context "when system instruction is set in conversation" do
      let(:system_instruction) { "You are a helpful assistant" }

      before do
        allow(conversation).to receive(:system_instruction).and_return(system_instruction)
      end

      it "creates a chat request with the conversation's system instruction" do
        expect(Geminize::Models::ChatRequest).to receive(:new).with(
          message, model_name, nil, {system_instruction: system_instruction}
        )
        chat.send_message(message, model_name)
      end
    end

    it "generates a response using the chat request" do
      expect(chat).to receive(:generate_response).with(chat_request)
      chat.send_message(message, model_name)
    end

    it "adds the model response to the conversation" do
      expect(conversation).to receive(:add_model_message).with("I'm doing well, thank you!")
      chat.send_message(message, model_name)
    end

    it "returns the chat response" do
      expect(chat.send_message(message, model_name)).to eq(chat_response)
    end
  end

  describe "#generate_response" do
    let(:chat_request) { instance_double(Geminize::Models::ChatRequest, model_name: "model-name") }
    let(:messages) { [{role: "user", parts: [{text: "Hello"}]}] }
    let(:payload) { {model: "model-name", contents: messages} }
    let(:response_data) { {"candidates" => [{"content" => {"parts" => [{"text" => "Hi there"}]}}]} }

    before do
      allow(conversation).to receive(:messages_as_hashes).and_return(messages)
      allow(Geminize::RequestBuilder).to receive(:build_text_generation_endpoint).and_return("endpoint")
      allow(Geminize::RequestBuilder).to receive(:build_chat_request).and_return(payload)
      allow(client).to receive(:post).and_return(response_data)
      allow(Geminize::Models::ChatResponse).to receive(:from_hash).and_return("response")
    end

    it "builds the endpoint using the model name" do
      expect(Geminize::RequestBuilder).to receive(:build_text_generation_endpoint).with("model-name")
      chat.generate_response(chat_request)
    end

    it "builds the request payload with the conversation history" do
      expect(Geminize::RequestBuilder).to receive(:build_chat_request).with(chat_request, messages)
      chat.generate_response(chat_request)
    end

    it "sends the request to the API" do
      expect(client).to receive(:post).with("endpoint", payload)
      chat.generate_response(chat_request)
    end

    it "returns a chat response from the API data" do
      expect(Geminize::Models::ChatResponse).to receive(:from_hash).with(response_data)
      expect(chat.generate_response(chat_request)).to eq("response")
    end
  end

  describe ".new_conversation" do
    let(:title) { "Test Conversation" }
    let(:system_instruction) { "You are a helpful assistant" }

    before do
      allow(Geminize::Models::Conversation).to receive(:new).and_return(conversation)
      allow(described_class).to receive(:new).and_return(chat)
    end

    it "creates a new conversation with the given title" do
      expect(Geminize::Models::Conversation).to receive(:new).with(nil, title, nil, nil, nil)
      described_class.new_conversation(title)
    end

    it "creates a new conversation with system instruction when provided" do
      expect(Geminize::Models::Conversation).to receive(:new).with(nil, title, nil, nil, system_instruction)
      described_class.new_conversation(title, system_instruction)
    end

    it "returns a new chat instance with the conversation" do
      expect(described_class).to receive(:new).with(conversation)
      expect(described_class.new_conversation(title)).to eq(chat)
    end
  end

  describe "#set_system_instruction" do
    let(:system_instruction) { "You are a helpful assistant" }

    it "sets the system instruction on the conversation" do
      expect(conversation).to receive(:system_instruction=).with(system_instruction)
      chat.set_system_instruction(system_instruction)
    end

    it "returns self for method chaining" do
      allow(conversation).to receive(:system_instruction=)
      expect(chat.set_system_instruction(system_instruction)).to eq(chat)
    end
  end
end
