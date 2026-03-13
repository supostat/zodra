# frozen_string_literal: true

module Api
  module V1
    class DashboardsController < ApplicationController
      include Zodra::Controller
      zodra_contract :dashboard

      def show
        zodra_respond(DashboardDataQuery.new.call)
      end
    end
  end
end
