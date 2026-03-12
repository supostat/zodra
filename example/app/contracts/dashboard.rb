# frozen_string_literal: true

Zodra.contract :dashboard do
  action :show do
    description "Admin dashboard with key business metrics"
    response do
      integer :total_orders
      money :total_revenue
      integer :active_customers
      integer :low_stock_products, description: "Products with stock below 10"
    end
  end
end
