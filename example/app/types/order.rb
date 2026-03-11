# frozen_string_literal: true

Zodra.type :order do
  uuid :id
  string :number
  order_status :status
  reference :customer
  array :line_items, of: :line_item
  reference :payment_method
  money :total_amount
  string? :shipping_address
  date :estimated_delivery, nullable: true
  timestamps
end
