# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'grape'
require 'sqlite3'
require 'active_record'
require_relative './models/holiday'

unless ActiveRecord::Base.connected?
  ActiveRecord::Base.configurations = YAML.load(ERB.new(IO.read('db/config.yml')).result)
  ActiveRecord::Base.establish_connection(ENV.fetch('ENV', 'development').to_sym)
end

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
