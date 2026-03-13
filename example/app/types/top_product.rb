# frozen_string_literal: true

Zodra.type :top_product do
  description "Product ranked by revenue"

  string :name
  string :sku
  integer :units_sold
  money :revenue
end
