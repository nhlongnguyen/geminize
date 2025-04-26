# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::TextGeneration do
  describe "streaming functionality" do
    let(:client) { instance_double(Geminize::Client) }
    let(:text_generation) { described_class.new(client) }
    let(:prompt) { "Tell me a story" }
    let(:custom_model) { "gemini-1.5-flash-latest" }

    let(:stream_response1) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "Once "
                }
              ],
              "role" => "model"
            },
            "index" => 0
          }
        ]
      }
    end

    let(:stream_response2) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "upon a "
                }
              ],
              "role" => "model"
            },
            "index" => 0
          }
        ]
      }
    end

    let(:stream_response3) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "time"
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ]
      }
    end

    # Response with usage metrics for final chunk testing
    let(:stream_response_with_metrics) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                {
                  "text" => "time"
                }
              ],
              "role" => "model"
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "usageMetadata" => {
          "promptTokenCount" => 10,
          "candidatesTokenCount" => 20,
          "totalTokenCount" => 30
        }
      }
    end

    describe "#generate_stream" do
      before do
        allow(Geminize::RequestBuilder).to receive(:build_text_generation_endpoint).and_return("models/gemini-1.5-pro-latest:generateContent")
        allow(Geminize::RequestBuilder).to receive(:build_text_generation_request).and_return({})

        # Mock StreamResponse behavior
        allow(Geminize::Models::StreamResponse).to receive(:from_hash).with(stream_response1).and_return(
          instance_double("Geminize::Models::StreamResponse",
            text: "Once ",
            final_chunk?: false,
            has_usage_metrics?: false)
        )

        allow(Geminize::Models::StreamResponse).to receive(:from_hash).with(stream_response2).and_return(
          instance_double("Geminize::Models::StreamResponse",
            text: "upon a ",
            final_chunk?: false,
            has_usage_metrics?: false)
        )

        allow(Geminize::Models::StreamResponse).to receive(:from_hash).with(stream_response3).and_return(
          instance_double("Geminize::Models::StreamResponse",
            text: "time",
            final_chunk?: true,
            has_usage_metrics?: false,
            finish_reason: "STOP")
        )

        allow(Geminize::Models::StreamResponse).to receive(:from_hash).with(stream_response_with_metrics).and_return(
          instance_double("Geminize::Models::StreamResponse",
            text: "time",
            final_chunk?: true,
            has_usage_metrics?: true,
            finish_reason: "STOP",
            prompt_tokens: 10,
            completion_tokens: 20,
            total_tokens: 30)
        )
      end

      it "yields chunks of streamed text with incremental mode (default)" do
        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)
          .and_yield(stream_response2)
          .and_yield(stream_response3)

        chunks = []
        text_generation.generate_text_stream(prompt) do |chunk|
          chunks << chunk
        end

        expect(chunks.length).to eq(3)
        expect(chunks[0]).to eq("Once ")
        expect(chunks[1]).to eq("Once upon a ")
        expect(chunks[2]).to eq("Once upon a time")
      end

      it "yields only delta chunks with delta mode" do
        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)
          .and_yield(stream_response2)
          .and_yield(stream_response3)

        chunks = []
        text_generation.generate_text_stream(prompt, nil, stream_mode: :delta) do |chunk|
          chunks << chunk
        end

        expect(chunks.length).to eq(3)
        expect(chunks[0]).to eq("Once ")
        expect(chunks[1]).to eq("upon a ")
        expect(chunks[2]).to eq("time")
      end

      it "yields raw response objects with raw mode" do
        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)
          .and_yield(stream_response2)
          .and_yield(stream_response3)

        chunks = []
        text_generation.generate_text_stream(prompt, nil, stream_mode: :raw) do |chunk|
          chunks << chunk
        end

        expect(chunks.length).to eq(3)
        expect(chunks[0]).to eq(stream_response1)
        expect(chunks[1]).to eq(stream_response2)
        expect(chunks[2]).to eq(stream_response3)
      end

      it "allows cancellation of streaming" do
        expect(client).to receive(:cancel_streaming=).with(true).and_return(true)

        expect(text_generation.cancel_streaming).to eq(true)
      end

      it "raises an error if no block is given" do
        expect {
          text_generation.generate_text_stream(prompt)
        }.to raise_error(ArgumentError, /A block is required for streaming/)
      end

      it "raises an error for invalid stream_mode" do
        expect {
          text_generation.generate_text_stream(prompt, nil, stream_mode: :invalid) { |_| }
        }.to raise_error(ArgumentError, /Invalid stream_mode. Must be :raw, :incremental, or :delta/)
      end

      it "uses the specified model" do
        expect(Geminize::Models::ContentRequest).to receive(:new).with(
          prompt,
          custom_model,
          {}
        ).and_call_original

        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)

        text_generation.generate_text_stream(prompt, custom_model) { |_| }
      end

      it "handles final chunks with usage metrics in incremental mode" do
        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)
          .and_yield(stream_response2)
          .and_yield(stream_response_with_metrics)

        chunks = []
        text_generation.generate_text_stream(prompt, nil, stream_mode: :incremental) do |chunk|
          chunks << chunk
        end

        expect(chunks.length).to eq(4) # 3 text chunks + 1 final metrics hash
        expect(chunks[0]).to eq("Once ")
        expect(chunks[1]).to eq("Once upon a ")
        expect(chunks[2]).to eq("Once upon a time")

        # Check the final metrics hash
        expect(chunks[3]).to be_a(Hash)
        expect(chunks[3][:text]).to eq("Once upon a time")
        expect(chunks[3][:finish_reason]).to eq("STOP")
        expect(chunks[3][:usage]).to be_a(Hash)
        expect(chunks[3][:usage][:prompt_tokens]).to eq(10)
        expect(chunks[3][:usage][:completion_tokens]).to eq(20)
        expect(chunks[3][:usage][:total_tokens]).to eq(30)
      end

      it "handles final chunks with usage metrics in delta mode" do
        expect(client).to receive(:post_stream)
          .and_yield(stream_response1)
          .and_yield(stream_response2)
          .and_yield(stream_response_with_metrics)

        chunks = []
        text_generation.generate_text_stream(prompt, nil, stream_mode: :delta) do |chunk|
          chunks << chunk
        end

        # First 3 chunks should be the text parts
        expect(chunks.length).to eq(4) # 3 text chunks + 1 final metrics hash
        expect(chunks[0]).to eq("Once ")
        expect(chunks[1]).to eq("upon a ")
        expect(chunks[2]).to eq("time")

        # Last chunk should be the metrics hash
        expect(chunks[3]).to be_a(Hash)
        expect(chunks[3][:text]).to eq("Once upon a time")
        expect(chunks[3][:finish_reason]).to eq("STOP")
        expect(chunks[3][:usage]).to be_a(Hash)
        expect(chunks[3][:usage][:prompt_tokens]).to eq(10)
        expect(chunks[3][:usage][:completion_tokens]).to eq(20)
        expect(chunks[3][:usage][:total_tokens]).to eq(30)
      end

      context "with streaming errors" do
        it "properly handles network interruptions during streaming" do
          # Configure the client to yield some successful chunks then raise a network error
          expect(client).to receive(:post_stream) do |&block|
            # First yield some successful chunks
            block.call(stream_response1)
            block.call(stream_response2)
            # Then simulate a network error
            raise Geminize::StreamingInterruptedError.new("Connection interrupted")
          end

          # Capture what chunks were received before the error
          received_chunks = []

          # The streaming should raise a StreamingInterruptedError
          expect {
            text_generation.generate_text_stream(prompt) do |chunk|
              received_chunks << chunk
            end
          }.to raise_error(Geminize::StreamingInterruptedError) do |error|
            # Error message should contain partial response information
            expect(error.message).to include("Connection interrupted")
            expect(error.message).to include("Partial response received")
            # Error should include the length of partial response received
            expect(error.message).to include("12 characters")
          end

          # We should have received the first two chunks before the error
          expect(received_chunks.length).to eq(2)
          expect(received_chunks[0]).to eq("Once ")
          expect(received_chunks[1]).to eq("Once upon a ")
        end

        it "wraps non-streaming specific exceptions in GeminizeError" do
          # Simulate a generic error during streaming
          expect(client).to receive(:post_stream).and_raise(StandardError.new("Unknown error"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::GeminizeError, /Error during text generation streaming: Unknown error/)
        end

        it "wraps GeminizeError subclasses in GeminizeError too" do
          # Specific GeminizeError subclasses are also wrapped
          error = Geminize::ValidationError.new("Invalid request")
          expect(client).to receive(:post_stream).and_raise(error)

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::GeminizeError, /Error during text generation streaming: Invalid request/)
        end
      end
    end
  end
end
