# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require_relative '../app/holidays'

describe Holidays::API do
  include Rack::Test::Methods

  def app
    Holidays::API
  end

  context 'GET /hello' do
    it 'returns hello world' do
      get '/hello'
      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = { 'hello' => 'world' }

      expect(actual).to eq(expected)
    end

    it 'two' do
      get '/hello'
      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = { 'hello' => 'world' }

      expect(actual).to eq(expected)
    end
  end
end
