# frozen_string_literal: true

module Api
  module V1
    class InternalMetricsController < ApplicationController
      include Zodra::Controller

      def show
        zodra_respond(
          total_orders: Order.count,
          total_revenue: Order.sum(:total_amount),
          active_customers: Customer.count
        )
      end
    end
  end
end
