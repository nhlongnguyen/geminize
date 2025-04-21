# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Error Handling" do
  describe Geminize::GeminizeError do
    it "initializes with a message, code, and http_status" do
      error = Geminize::GeminizeError.new("Test error", "ERROR_CODE", 400)
      expect(error.message).to eq("Test error")
      expect(error.code).to eq("ERROR_CODE")
      expect(error.http_status).to eq(400)
    end

    it "uses a default message if none is provided" do
      error = Geminize::GeminizeError.new
      expect(error.message).to eq("An error occurred with the Geminize API")
    end
  end

  describe Geminize::ErrorParser do
    let(:response) do
      instance_double(
        "Faraday::Response",
        status: 400,
        body: {
          "error" => {
            "code" => 400,
            "message" => "Invalid argument",
            "status" => "INVALID_ARGUMENT"
          }
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )
    end

    it "extracts error information from a response" do
      error_info = Geminize::ErrorParser.parse(response)
      expect(error_info[:http_status]).to eq(400)
      expect(error_info[:code]).to eq("400")
      expect(error_info[:message]).to eq("Invalid argument")
    end

    context "with empty response body" do
      let(:response) do
        instance_double(
          "Faraday::Response",
          status: 400,
          body: "",
          headers: {"Content-Type" => "application/json"}
        )
      end

      it "uses default error message" do
        error_info = Geminize::ErrorParser.parse(response)
        expect(error_info[:message]).to eq("Bad Request: The server could not process the request")
      end
    end

    context "with non-JSON response" do
      let(:response) do
        instance_double(
          "Faraday::Response",
          status: 500,
          body: "Internal Server Error",
          headers: {"Content-Type" => "text/plain"}
        )
      end

      it "uses default error message" do
        error_info = Geminize::ErrorParser.parse(response)
        expect(error_info[:message]).to eq("Server Error: The server encountered an error (500)")
      end
    end
  end

  describe Geminize::ErrorMapper do
    it "maps HTTP status codes to appropriate error classes" do
      expect(Geminize::ErrorMapper.map(http_status: 400, code: nil, message: nil)).to be_a(Geminize::BadRequestError)
      expect(Geminize::ErrorMapper.map(http_status: 401, code: nil,
        message: nil)).to be_a(Geminize::AuthenticationError)
      expect(Geminize::ErrorMapper.map(http_status: 403, code: nil,
        message: nil)).to be_a(Geminize::AuthenticationError)
      expect(Geminize::ErrorMapper.map(http_status: 404, code: nil,
        message: nil)).to be_a(Geminize::ResourceNotFoundError)
      expect(Geminize::ErrorMapper.map(http_status: 429, code: nil, message: nil)).to be_a(Geminize::RateLimitError)
      expect(Geminize::ErrorMapper.map(http_status: 500, code: nil, message: nil)).to be_a(Geminize::ServerError)
    end

    it "maps API error codes to appropriate error classes" do
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "UNAUTHORIZED",
        message: nil)).to be_a(Geminize::AuthenticationError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "QUOTA_EXCEEDED",
        message: nil)).to be_a(Geminize::RateLimitError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "NOT_FOUND",
        message: nil)).to be_a(Geminize::ResourceNotFoundError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "INVALID_MODEL",
        message: nil)).to be_a(Geminize::InvalidModelError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "VALIDATION_ERROR",
        message: nil)).to be_a(Geminize::ValidationError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "CONTENT_BLOCKED",
        message: nil)).to be_a(Geminize::ContentBlockedError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "INTERNAL_SERVER_ERROR",
        message: nil)).to be_a(Geminize::ServerError)
      expect(Geminize::ErrorMapper.map(http_status: nil, code: "CONFIG_ERROR",
        message: nil)).to be_a(Geminize::ConfigurationError)
    end

    it "prefers API error codes over HTTP status" do
      error = Geminize::ErrorMapper.map(http_status: 400, code: "QUOTA_EXCEEDED", message: nil)
      expect(error).to be_a(Geminize::RateLimitError)
    end

    it "falls back to GeminizeError for unknown errors" do
      error = Geminize::ErrorMapper.map(http_status: nil, code: "UNKNOWN_ERROR", message: nil)
      expect(error).to be_a(Geminize::GeminizeError)
    end
  end
end
