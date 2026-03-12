# frozen_string_literal: true

Zodra.contract :internal_metrics do
  openapi false

  action :show do
    response do
      integer :total_orders
      integer :total_revenue
      integer :active_customers
    end
  end
end
