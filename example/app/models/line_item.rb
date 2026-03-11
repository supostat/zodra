# frozen_string_literal: true

class LineItem < ApplicationRecord
  before_create { self.id = SecureRandom.uuid if id.blank? }

  belongs_to :order
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_total_price

  private

  def calculate_total_price
    self.total_price = (unit_price || 0) * (quantity || 0)
  end
end
