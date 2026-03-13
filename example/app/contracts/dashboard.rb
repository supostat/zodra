# frozen_string_literal: true

Zodra.contract :dashboard do
  action :show do
    description "Admin dashboard with key business metrics"
    response do
      reference :overview, to: :dashboard_overview
      array :revenue_by_status, of: :revenue_breakdown
      array :top_products, of: :top_product
    end
  end
end
