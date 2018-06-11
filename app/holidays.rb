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

    def filter_by_year(year)
      holidays = @repository.all_by_year(year)

      raise NotFoundError, 'No holidays found!' if holidays.empty?

      @serializer.all(holidays)
    end

    def filter_by_month(year, month)
      holidays = @repository.all_by_month(year, month)

      raise NotFoundError, 'No holidays found!' if holidays.empty?

      @serializer.all(holidays)
    end
  end

  class API < Grape::API
    format :json

    resource :holidays do
      get do
        Service.new.all
      end

      resource :year do
        params do
          requires :year_param, type: Integer, desc: 'Year.'
        end
        route_param :year_param do
          get do
            begin
              Service.new.filter_by_year(params[:year_param])
            rescue NotFoundError => e
              error!({ error: 'not_found', message: e.message }, 404)
            end
          end

          resource :month do
            params do
              requires :month_param, type: Integer, desc: 'Month.', values: (1..12).to_a
            end
            route_param :month_param do
              get do
                begin
                  Service.new.filter_by_month(params[:year_param], params[:month_param])
                rescue NotFoundError => e
                  error!({ error: 'not_found', message: e.message }, 404)
                end
              end
            end
          end
        end
      end
    end
  end
end
