# frozen_string_literal: true

class Product < ApplicationRecord
  before_create { self.id = SecureRandom.uuid if id.blank? }

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
