# frozen_string_literal: true

Zodra.type :product do
  description "A product in the catalog"

  uuid :id
  string :name, description: "Display name"
  string :sku, description: "Stock keeping unit, unique per product"
  money :price, description: "Price in store currency"
  integer :stock, min: 0, description: "Available inventory count"
  boolean :published
  string :legacy_code, deprecated: true, description: "Use sku instead"
end
