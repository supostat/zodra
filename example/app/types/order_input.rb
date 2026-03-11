# frozen_string_literal: true

Zodra.type :order_input do
  uuid :customer_id
  string? :shipping_address
  array :items, of: :order_item_input
end
