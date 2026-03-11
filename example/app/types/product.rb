# frozen_string_literal: true

Zodra.type :product do
  uuid :id
  string :name
  string :sku
  money :price
  integer :stock
  boolean :published
end
