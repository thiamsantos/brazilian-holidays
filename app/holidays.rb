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

  class NotFoundError < StandardError
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

      raise NotFoundError, 'No holidays found!' if holidays.empty?

      @serializer.all(holidays)
    end

    def all_by_month(year, month)
      holidays = @repository.all_by_month(year, month)

      raise NotFoundError, 'No holidays found!' if holidays.empty?

      @serializer.all(holidays)
    end

    def one_by_date(date)
      holiday = @repository.one_by_date(date)

      raise NotFoundError, 'No holidays found!' if holiday.nil?

      @serializer.one(holiday)
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
    # rubocop:disable Metrics/BlockLength
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
        rescue NotFoundError => e
          error!({ error: 'not_found', message: e.message }, 404)
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
            rescue NotFoundError => e
              error!({ error: 'not_found', message: e.message }, 404)
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
                rescue NotFoundError => e
                  error!({ error: 'not_found', message: e.message }, 404)
                end
              end
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
