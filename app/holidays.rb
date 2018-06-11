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
  class Service
    def self.all
      Holiday
        .select(:occurs_at, :name)
        .map { |holiday| { name: holiday[:name], date: holiday[:occurs_at] } }
    end

    def self.filter_by_year(year)
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, -1, -1)

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
        Service.all
      end

      resource :year do
        route_param :year_id do
          get do
            year = params[:year_id].to_i

            if year.zero?
              message = "`#{params[:year_id]}` is not a valid year!"
              error!({ error: 'invalid', message: message }, 400)
            end

            holidays = Service.filter_by_year(year)

            if holidays.empty?
              error!({ error: 'not_found', message: 'No holidays found!' }, 404)
            end

            holidays
          end
        end
      end
    end
  end
end
