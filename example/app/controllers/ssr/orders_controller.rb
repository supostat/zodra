# frozen_string_literal: true

module Ssr
  class OrdersController < BaseController
    def index
      orders = Order.includes(:customer, line_items: :product).all
      @props = { orders: zodra_serialize_many(orders, :order) }
    end

    def show
      order = Order.includes(:customer, line_items: :product).find(params[:id])
      @props = { order: zodra_serialize(order, :order) }
    end
  end
end
