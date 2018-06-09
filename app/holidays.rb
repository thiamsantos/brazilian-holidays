# frozen_string_literal: true

require 'grape'
require 'sqlite3'
require 'active_record'
require_relative './models/holiday'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/development.sqlite3'
)

module Holidays
  class API < Grape::API
    format :json

    get :hello do
      { hello: 'world' }
    end

    get :all do
      Holiday.all
    end
  end
end
