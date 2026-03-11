# frozen_string_literal: true

Zodra.type :line_item do
  uuid :id
  reference :product
  integer :quantity, min: 1
  money :unit_price
  money :total_price
end
