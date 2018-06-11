# frozen_string_literal: true

require 'spec_helper'
require 'rack/test'
require 'timecop'
require_relative '../app/holidays'

describe Holidays::API do
  include Rack::Test::Methods

  def app
    Holidays::API
  end

  before do
    Timecop.freeze(Date.new(2018, 6, 11))
  end

  after do
    Timecop.return
  end

  context 'GET /holidays' do
    it 'shoould return all holidays' do
      today = Date.today
      name = 'Holiday'
      Holiday.create(name: name, occurs_at: today)

      get '/holidays'
      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => today.to_s }]

      expect(actual).to eq(expected)
    end
  end

  context 'GET /holidays/year/year' do
    it 'should return the holidays by year' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holiday.create(name: name, occurs_at: date)
      Holiday.create(name: 'another', occurs_at: Date.new(2009, 4, 10))

      get '/holidays/year/2017'

      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => date.to_s }]

      expect(actual).to eq(expected)
    end

    it 'should return 404 when no holidays exists in the specified year' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holiday.create(name: name, occurs_at: date)

      get '/holidays/year/2004'

      expect(last_response.status).to eq(404)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'not_found', 'message' => 'No holidays found!' }

      expect(actual).to eq(expected)
    end

    it 'should return 400 for invalid years' do
      get '/holidays/year/invalid'

      expect(last_response.status).to eq(400)
      actual = JSON.parse(last_response.body)
      message = '`invalid` is not a valid year!'
      expected = { 'error' => 'invalid', 'message' => message }

      expect(actual).to eq(expected)
    end
  end
end
