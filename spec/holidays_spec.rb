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
      Holidays::Holiday.create(name: name, occurs_at: today)

      get '/holidays'
      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => today.to_s }]

      expect(actual).to eq(expected)
    end
  end

  context 'GET /holidays/year/{year_param}' do
    it 'should return the holidays by year' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      holidays = [
        { name: name, occurs_at: date },
        { name: 'another', occurs_at: Date.new(2009, 4, 10) },
        { name: 'another 1', occurs_at: Date.new(2018) },
        { name: 'another 2', occurs_at: Date.new(2016, -1, -1) }
      ]

      holidays.each do |holiday|
        Holidays::Holiday.create(holiday)
      end

      get '/holidays/year/2017'

      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => date.to_s }]

      expect(actual).to eq(expected)
    end

    it 'should return 404 when no holidays exists in the specified year' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holidays::Holiday.create(name: name, occurs_at: date)

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
      expected = { 'error' => 'year_param is invalid' }

      expect(actual).to eq(expected)
    end
  end

  context 'GET /holidays/year/{year_param}/month/{month_param}' do
    it 'should return the holidays by month' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holidays::Holiday.create(name: name, occurs_at: date)
      Holidays::Holiday.create(name: 'another', occurs_at: date.next_month)

      get '/holidays/year/2017/month/4'

      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => date.to_s }]

      expect(actual).to eq(expected)
    end

    it 'should return the holidays of december' do
      date = Date.new(2017, 12, 15)
      name = 'Holiday'

      Holidays::Holiday.create(name: name, occurs_at: date)

      get '/holidays/year/2017/month/12'

      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = [{ 'name' => name, 'date' => date.to_s }]

      expect(actual).to eq(expected)
    end

    it 'should return 404 when no holidays exists in the specified month' do
      get '/holidays/year/2017/month/5'

      expect(last_response.status).to eq(404)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'not_found', 'message' => 'No holidays found!' }

      expect(actual).to eq(expected)
    end

    it 'should return 400 for invalid months' do
      get '/holidays/year/2017/month/27'

      expect(last_response.status).to eq(400)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'month_param does not have a valid value' }

      expect(actual).to eq(expected)
    end

    it 'should return 400 for invalid year and month' do
      get '/holidays/year/pow/month/27'

      expect(last_response.status).to eq(400)
      actual = JSON.parse(last_response.body)
      message = 'year_param is invalid, month_param does not have a valid value'
      expected = { 'error' => message }

      expect(actual).to eq(expected)
    end
  end

  context 'GET /holidays?date={date}' do
    it 'should return the holiday that occurs in that day' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holidays::Holiday.create(name: name, occurs_at: date)
      Holidays::Holiday.create(name: 'test', occurs_at: Date.new(2017, 4, 16))

      get '/holidays?date=2017-04-15'

      expect(last_response.status).to eq(200)
      actual = JSON.parse(last_response.body)
      expected = { 'name' => name, 'date' => date.to_s }

      expect(actual).to eq(expected)
    end

    it 'should return 404 when that day is not a holiday' do
      date = Date.new(2017, 4, 15)
      name = 'Holiday'

      Holidays::Holiday.create(name: name, occurs_at: date)

      get '/holidays?date=2017-04-16'

      expect(last_response.status).to eq(404)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'not_found', 'message' => 'No holidays found!' }

      expect(actual).to eq(expected)
    end

    it 'should return 400 if the date format is invalid' do
      get '/holidays?date=201-4-5'

      expect(last_response.status).to eq(400)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'date is invalid' }

      expect(actual).to eq(expected)
    end

    it 'should return 400 if the date format is invalid' do
      get '/holidays?date=2017-02-30'

      expect(last_response.status).to eq(400)
      actual = JSON.parse(last_response.body)
      expected = { 'error' => 'date is invalid' }

      expect(actual).to eq(expected)
    end
  end
end
