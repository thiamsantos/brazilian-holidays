# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'grape'
require 'sqlite3'
require 'active_record'
require_relative './models/holiday'

unless ActiveRecord::Base.connected?
  configuration_file = ERB.new(IO.read('db/config.yml')).result
  env = ENV.fetch('ENV', 'development').to_sym

  ActiveRecord::Base.configurations = YAML.safe_load(configuration_file)
  ActiveRecord::Base.establish_connection(env)
end

module Holidays
  class NotFoundError < StandardError
  end

  class Service
    def all
      Holiday
        .select(:occurs_at, :name)
        .map { |holiday| { name: holiday[:name], date: holiday[:occurs_at] } }
    end

    def filter_by_year(year)
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, -1, -1)

      holidays = query_by_year(start_date, end_date)

      raise NotFoundError, 'No holidays found!' if holidays.empty?

      holidays
    end

    private

    def query_by_year(start_date, end_date)
      Holiday
        .select(:occurs_at, :name)
        .where('occurs_at >= ? and occurs_at <= ?', start_date, end_date)
        .map do |holiday|
          { name: holiday[:name], date: holiday[:occurs_at] }
        end
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
        end
      end
    end
  end
end
