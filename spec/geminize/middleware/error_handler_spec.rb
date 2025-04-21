# frozen_string_literal: true

require "spec_helper"

RSpec.describe Geminize::Middleware::ErrorHandler do
  let(:app) { double("Faraday app") }
  let(:middleware) { described_class.new(app) }
  let(:env) { Faraday::Env.new }
  let(:response) { double("Faraday::Response", on_complete: nil) }

  before do
    allow(app).to receive(:call).and_return(response)
    allow(response).to receive(:on_complete).and_yield(env)
  end

  describe "#initialize" do
    it "defaults error_statuses to 400..599" do
      expect(middleware.error_statuses).to include(400, 404, 429, 500, 503)
    end

    it "accepts custom error_statuses" do
      custom_middleware = described_class.new(app, error_statuses: [400, 401])
      expect(custom_middleware.error_statuses).to eq([400, 401])
    end
  end

  describe "#call" do
    context "when response is successful" do
      before do
        env.status = 200
      end

      it "does not call on_complete" do
        expect(middleware).not_to receive(:on_complete)
        middleware.call(env)
      end
    end

    context "when response has an error status" do
      before do
        env.status = 401
        env.body = {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }.to_json
        allow(Geminize::ErrorParser).to receive(:parse).and_return({
          http_status: 401,
          code: "401",
          message: "Unauthorized"
        })
        allow(Geminize::ErrorMapper).to receive(:map).and_return(
          Geminize::AuthenticationError.new("Unauthorized", "401", 401)
        )
      end

      it "parses the response and raises an appropriate error" do
        expect(Geminize::ErrorParser).to receive(:parse)
        expect(Geminize::ErrorMapper).to receive(:map)
        expect { middleware.call(env) }.to raise_error(Geminize::AuthenticationError)
      end
    end

    context "when there's a network error" do
      it "raises a RequestError for connection failures" do
        allow(app).to receive(:call).and_raise(Faraday::ConnectionFailed.new("Connection failed"))
        expect { middleware.call(env) }.to raise_error(Geminize::RequestError, /Connection failed/)
      end

      it "raises a RequestError for timeouts" do
        allow(app).to receive(:call).and_raise(Faraday::TimeoutError.new("Timeout"))
        expect { middleware.call(env) }.to raise_error(Geminize::RequestError, /Timeout/)
      end
    end
  end
end
