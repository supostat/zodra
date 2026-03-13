# frozen_string_literal: true

module Admin
  class DashboardsController < BaseController
    def show
      @props = DashboardDataQuery.new.call
    end
  end
end
