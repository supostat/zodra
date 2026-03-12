# frozen_string_literal: true

module Admin
  class DashboardsController < ApplicationController
    include Zodra::Controller
    zodra_contract :dashboard

    def show
      zodra_respond({
        total_orders: Order.count,
        total_revenue: Order.sum(:total_amount),
        active_customers: Customer.count,
        low_stock_products: Product.where('stock < 10').count
      })
    end
  end
end
