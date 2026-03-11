# frozen_string_literal: true

Zodra.scalar :money, base: :decimal do |value|
  BigDecimal(value.to_s).round(2)
rescue ArgumentError
  :coercion_error
end
