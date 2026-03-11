# frozen_string_literal: true

Zodra.type :product do
  uuid :id
  string :name
  string :sku
  decimal :price
  integer :stock
  boolean :published
end
