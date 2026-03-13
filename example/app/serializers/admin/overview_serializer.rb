# frozen_string_literal: true

module Admin
  class OverviewSerializer < Oj::Serializer
    object_as :object
    serializer_attributes \
      :total_orders,
      :total_revenue,
      :average_order_value,
      :active_customers,
      :low_stock_products

    def total_orders
      memo.fetch(:total_orders) { Order.count }
    end

    def total_revenue
      memo.fetch(:total_revenue) { Order.sum(:total_amount) }.to_f
    end

    def average_order_value
      return 0.0 if total_orders.zero?

      (BigDecimal(total_revenue.to_s) / total_orders).round(2).to_f
    end

    def active_customers
      Customer.count
    end

    def low_stock_products
      Product.where("stock < ?", stock_threshold).count
    end

    private

    def stock_threshold
      options.fetch(:stock_threshold, 10)
    end
  end
end
