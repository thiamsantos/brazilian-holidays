# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'grape'
require 'sqlite3'
require 'active_record'

unless ActiveRecord::Base.connected?
  configuration_file = ERB.new(IO.read('db/config.yml')).result
  env = ENV.fetch('ENV', 'development').to_sym

  ActiveRecord::Base.configurations = YAML.safe_load(configuration_file)
  ActiveRecord::Base.establish_connection(env)
end

module Holidays
  class Holiday < ActiveRecord::Base
  end

  class HolidayError < StandardError
    attr_reader :type, :code
    def initialize(msg = 'Holiday Error!', type = 'holiday_error', code = 422)
      @type = type
      @code = code
      super(msg)
    end
  end

  class NotFoundError < HolidayError
    def self.create
      new('No holidays found!', 'not_found', 404)
    end
  end

  class InvalidRangeError < HolidayError
    def self.create_same_dates
      new('Start and end dates are the same!', 'invalid_range', 422)
    end

    def self.create_start_is_greater
      new('Start date is greater than end date!', 'invalid_range', 422)
    end
  end

  class HolidayRepository
    def initialize(relation = Holiday.unscoped)
      @relation = relation
    end

    def all
      @relation
        .select(:occurs_at, :name)
    end

    def all_by_year(year)
      start_date = Date.new(year)
      end_date = start_date.next_year

      range = start_date...end_date
      all_by_range(range)
    end

    def all_by_month(year, month)
      start_date = Date.new(year, month)
      end_date = start_date.next_month

      range = start_date...end_date
      all_by_range(range)
    end

    def all_by_range(range)
      all.where('occurs_at >= ? and occurs_at <= ?', range.min, range.max)
    end

    def one_by_date(date)
      Holiday.where(occurs_at: date).first
    end
  end

  class HolidaySerializer
    def all(holidays)
      holidays.map { |holiday| one(holiday) }
    end

    def one(holiday)
      { name: holiday[:name], date: holiday[:occurs_at] }
    end
  end

  class Service
    def initialize
      @repository = HolidayRepository.new
      @serializer = HolidaySerializer.new
    end

    def all
      @serializer.all(@repository.all)
    end

    def all_by_year(year)
      holidays = @repository.all_by_year(year)

      raise NotFoundError.create if holidays.empty?

      @serializer.all(holidays)
    end

    def all_by_month(year, month)
      holidays = @repository.all_by_month(year, month)

      raise NotFoundError.create if holidays.empty?

      @serializer.all(holidays)
    end

    def all_by_range(range)
      holidays = @repository.all_by_range(validate_range(range))

      raise NotFoundError.create if holidays.empty?

      @serializer.all(holidays)
    end

    def one_by_date(date)
      holiday = @repository.one_by_date(date)

      raise NotFoundError.create if holiday.nil?

      @serializer.one(holiday)
    end

    private

    def validate_range(range)
      raise InvalidRangeError.create_same_dates if range.begin == range.end
      raise InvalidRangeError.create_start_is_greater if range.begin > range.end
      range
    end
  end

  class DateParam
    def self.parse(value)
      raise 'Invalid date' if /\d{4}-\d{2}-\d{2}/.match(value).nil?

      Date.parse(value)
    end

    def self.parsed?(value)
      value.is_a?(Date)
    end
  end

  class API < Grape::API
    format :json

    resource :holidays do
      params do
        optional :date, type: DateParam
      end

      get do
        begin
          date = params[:date]
          return Service.new.all if date.nil?

          Service.new.one_by_date(date)
        rescue HolidayError => e
          error!({ error: e.type, message: e.message }, e.code)
        end
      end

      resource :range do
        params do
          requires :start, type: DateParam
          requires :end, type: DateParam
        end
        get do
          begin
            start_date = params[:start]
            end_date = params[:end]

            Service.new.all_by_range(start_date...end_date)
          rescue HolidayError => e
            error!({ error: e.type, message: e.message }, e.code)
          end
        end
      end

      resource :year do
        params do
          requires :year_param, type: Integer
        end
        route_param :year_param do
          get do
            begin
              Service.new.all_by_year(params[:year_param])
            rescue HolidayError => e
              error!({ error: e.type, message: e.message }, e.code)
            end
          end

          resource :month do
            params do
              requires :month_param, type: Integer, values: (1..12).to_a
            end
            route_param :month_param do
              get do
                begin
                  year = params[:year_param]
                  month = params[:month_param]
                  Service.new.all_by_month(year, month)
                rescue HolidayError => e
                  error!({ error: e.type, message: e.message }, e.code)
                end
              end
            end
          end
        end
      end
    end

    route :any, '*path' do
      error!({ error: 'not_found', message: 'Not found!' }, 404)
    end
  end
end
