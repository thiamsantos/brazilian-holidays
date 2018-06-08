# frozen_string_literal: true

require 'grape'

module Holidays
  class API < Grape::API
    format :json

    get :hello do
      { hello: 'world' }
    end
  end
end
