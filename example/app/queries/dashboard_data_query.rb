# frozen_string_literal: true

class DashboardDataQuery
  STOCK_THRESHOLD = 10
  TOP_PRODUCTS_LIMIT = 5

  def call
    {
      overview: Admin::OverviewSerializer.one(nil, stock_threshold: STOCK_THRESHOLD),
      revenue_by_status: Admin::RevenueBreakdownSerializer.many(revenue_by_status),
      top_products: Admin::TopProductSerializer.many(top_products)
    }
  end

  private

  def revenue_by_status
    Order
      .group(:status)
      .select("status, SUM(total_amount) AS total, COUNT(*) AS count")
  end

  def top_products
    LineItem
      .joins(:product)
      .group("products.name", "products.sku")
      .select(
        "products.name AS name",
        "products.sku AS sku",
        "SUM(line_items.quantity) AS units_sold",
        "SUM(line_items.total_price) AS revenue"
      )
      .order("revenue DESC")
      .limit(TOP_PRODUCTS_LIMIT)
  end
end
