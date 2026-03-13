# frozen_string_literal: true

Zodra.type :dashboard_overview do
  description "Aggregate order and inventory metrics"

  integer :total_orders
  money :total_revenue
  money :average_order_value
  integer :active_customers
  integer :low_stock_products
end
