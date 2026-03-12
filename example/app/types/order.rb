# frozen_string_literal: true

Zodra.type :order do
  description "A customer order with line items and payment"

  uuid :id
  string :number, description: "Human-readable order number"
  order_status :status
  reference :customer
  array :line_items, of: :line_item
  reference :payment_method
  money :total_amount
  string? :shipping_address
  date :estimated_delivery, nullable: true, description: "Estimated delivery date, null if unknown"
  timestamps
end
