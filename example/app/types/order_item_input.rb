# frozen_string_literal: true

Zodra.type :order_item_input do
  uuid :product_id
  integer :quantity, min: 1
end
