# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Geminize::Client do
  let(:api_key) { "test-api-key" }
  let(:api_version) { "v1beta" }
  let(:default_model) { "gemini-2.0-flash" }
  let(:client) { described_class.new }

  before do
    allow(Geminize.configuration).to receive(:api_key).and_return(api_key)
    allow(Geminize.configuration).to receive(:api_version).and_return(api_version)
    allow(Geminize.configuration).to receive(:default_model).and_return(default_model)
    allow(Geminize.configuration).to receive(:timeout).and_return(30)
    allow(Geminize.configuration).to receive(:open_timeout).and_return(10)
    allow(Geminize.configuration).to receive(:api_base_url).and_return("https://generativelanguage.googleapis.com")
  end

  describe "#initialize" do
    it "creates a Faraday connection with the configured base URL" do
      expect(client.connection.url_prefix.to_s).to eq("https://generativelanguage.googleapis.com/")
    end

    it "configures the connection with the right timeouts" do
      expect(client.connection.options.timeout).to eq(30)
      expect(client.connection.options.open_timeout).to eq(10)
    end
  end

  describe "#get" do
    let(:endpoint) { "path/to/endpoint" }
    let(:expected_url) { "https://generativelanguage.googleapis.com/v1beta/path/to/endpoint?key=test-api-key" }

    before do
      stub_request(:get, expected_url)
        .to_return(status: 200, body: '{"result": "success"}', headers: {"Content-Type" => "application/json"})
    end

    it "makes a GET request to the specified endpoint with the API key" do
      client.get(endpoint)
      expect(WebMock).to have_requested(:get, expected_url)
    end

    it "returns the parsed JSON response" do
      response = client.get(endpoint)
      expect(response).to eq({"result" => "success"})
    end
  end

  describe "#post" do
    let(:endpoint) { "path/to/endpoint" }
    let(:expected_url) { "https://generativelanguage.googleapis.com/v1beta/path/to/endpoint?key=test-api-key" }
    let(:payload) { {data: "test"} }

    before do
      stub_request(:post, expected_url)
        .with(body: payload.to_json)
        .to_return(status: 200, body: '{"result": "success"}', headers: {"Content-Type" => "application/json"})
    end

    it "makes a POST request to the specified endpoint with the API key and JSON body" do
      client.post(endpoint, payload)
      expect(WebMock).to have_requested(:post, expected_url)
        .with(body: payload.to_json, headers: {"Content-Type" => "application/json"})
    end

    it "returns the parsed JSON response" do
      response = client.post(endpoint, payload)
      expect(response).to eq({"result" => "success"})
    end
  end

  describe "error handling" do
    let(:endpoint) { "path/to/endpoint" }
    let(:expected_url) { "https://generativelanguage.googleapis.com/v1beta/path/to/endpoint?key=test-api-key" }

    it "raises an error on timeout" do
      stub_request(:get, expected_url).to_timeout

      expect { client.get(endpoint) }.to raise_error(Geminize::RequestError)
    end

    it "raises an error for a server error response" do
      stub_request(:get, expected_url)
        .to_return(status: 500, body: '{"error": "Internal Server Error"}')

      expect { client.get(endpoint) }.to raise_error(Geminize::ServerError)
    end

    it "raises an error for an invalid request" do
      stub_request(:get, expected_url)
        .to_return(status: 400, body: '{"error": "Bad Request"}')

      expect { client.get(endpoint) }.to raise_error(Geminize::BadRequestError)
    end
  end
end
