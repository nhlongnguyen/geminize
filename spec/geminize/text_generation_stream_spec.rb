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
        allow(client).to receive(:cancel_streaming).and_return(true)

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

        expect(chunks.length).to eq(4) # 3 text chunks + 1 final metrics hash
        expect(chunks[0]).to eq("Once ")
        expect(chunks[1]).to eq("upon a ")
        expect(chunks[2]).to eq("time")

        # Check the final metrics hash
        expect(chunks[3]).to be_a(Hash)
        expect(chunks[3][:text]).to eq("Once upon a time")
        expect(chunks[3][:finish_reason]).to eq("STOP")
        expect(chunks[3][:usage]).to be_a(Hash)
        expect(chunks[3][:usage][:prompt_tokens]).to eq(10)
        expect(chunks[3][:usage][:completion_tokens]).to eq(20)
        expect(chunks[3][:usage][:total_tokens]).to eq(30)
      end

      context "with error handling" do
        it "raises StreamingError when streaming fails" do
          allow(client).to receive(:post_stream).and_raise(Geminize::StreamingError.new("Network error"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::StreamingError, /Network error/)
        end

        it "raises StreamingInterruptedError when streaming is interrupted" do
          allow(client).to receive(:post_stream).and_raise(Geminize::StreamingInterruptedError.new("Connection interrupted"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::StreamingInterruptedError, /Connection interrupted/)
        end

        it "raises StreamingTimeoutError when streaming times out" do
          allow(client).to receive(:post_stream).and_raise(Geminize::StreamingTimeoutError.new("Connection timed out"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::StreamingTimeoutError, /Connection timed out/)
        end

        it "raises InvalidStreamFormatError when stream format is invalid" do
          allow(client).to receive(:post_stream).and_raise(Geminize::InvalidStreamFormatError.new("Invalid stream format"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::InvalidStreamFormatError, /Invalid stream format/)
        end

        it "adds partial response context to error message when chunks were received" do
          # First yield some successful chunks, then raise an error
          allow(client).to receive(:post_stream) do |&block|
            block.call(stream_response1)
            block.call(stream_response2)
            raise Geminize::StreamingInterruptedError.new("Connection interrupted")
          end

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::StreamingInterruptedError, /Connection interrupted.*Partial response received:.*characters/)
        end

        it "wraps non-streaming errors in GeminizeError" do
          allow(client).to receive(:post_stream).and_raise(StandardError.new("Unknown error"))

          expect {
            text_generation.generate_text_stream(prompt) { |_| }
          }.to raise_error(Geminize::GeminizeError, /Error during text generation streaming: Unknown error/)
        end
      end
    end
  end
end
