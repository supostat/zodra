# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      include Zodra::Controller

      zodra_contract :orders

      zodra_rescue :confirm, InvalidTransitionError, as: :invalid_transition
      zodra_rescue :cancel, InvalidTransitionError, as: :invalid_transition

      def index
        orders = Order.includes(:customer, line_items: :product).all
        zodra_respond_collection(orders)
      end

      def show
        order = Order.includes(:customer, line_items: :product).find(zodra_params[:id])
        zodra_respond(order)
      end

      def create
        order = build_order
        zodra_respond(order, status: :created)
      end

      def confirm
        order = Order.find(zodra_params[:id])
        order.confirm!
        zodra_respond(order.reload)
      end

      def cancel
        order = Order.find(zodra_params[:id])
        order.cancel!
        zodra_respond(order.reload)
      end

      def search
        orders = Order.includes(:customer, line_items: :product)
        orders = orders.where(status: zodra_params[:status]) if zodra_params[:status]
        orders = orders.where('orders.created_at >= ?', zodra_params[:from_date]) if zodra_params[:from_date]
        orders = orders.where('orders.created_at <= ?', zodra_params[:to_date]) if zodra_params[:to_date]
        zodra_respond_collection(orders)
      end

      private

      def build_order
        ActiveRecord::Base.transaction do
          order = Order.create!(
            customer_id: zodra_params[:customer_id],
            shipping_address: zodra_params[:shipping_address]
          )

          zodra_params[:items].each do |item|
            product = Product.find(item[:product_id])
            order.line_items.create!(
              product: product,
              quantity: item[:quantity],
              unit_price: product.price
            )
          end

          order.recalculate_total!
          order.reload
        end
      end
    end
  end
end
