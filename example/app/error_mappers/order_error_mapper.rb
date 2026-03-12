# frozen_string_literal: true

class OrderErrorMapper < Zodra::ErrorMapper
  def call(order:)
    collect(order) do
      ignore :number, :status, :total_amount
      map_remaining
    end

    item_errors = build_item_errors(order.line_items)
    result[:items] = item_errors if item_errors.any?

    result
  end

  private

  def build_item_errors(line_items)
    line_items.filter_map do |line_item|
      next if line_item.errors.empty?

      mapped = {}
      line_item.errors.to_hash.each do |key, messages|
        next if %i[order unit_price total_price].include?(key)

        mapped_key = key == :product ? :product_id : key
        mapped[mapped_key] = messages
      end
      mapped.presence
    end
  end
end
