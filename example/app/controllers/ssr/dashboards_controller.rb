# frozen_string_literal: true

module Ssr
  class DashboardsController < BaseController
    def show
      data = DashboardDataQuery.new.call
      @props = camelize_keys(data)
    end
  end
end
