# frozen_string_literal: true

Zodra.type :revenue_breakdown do
  description "Revenue aggregated by order status"

  string :status
  money :total
  integer :count
end
