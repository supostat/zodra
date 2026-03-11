# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = %w[draft confirmed shipped delivered cancelled].freeze

  before_create { self.id = SecureRandom.uuid if id.blank? }

  belongs_to :customer
  has_many :line_items, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_number, on: :create

  def confirm!
    raise InvalidTransitionError, 'Only draft orders can be confirmed' unless status == 'draft'

    update!(status: 'confirmed', estimated_delivery: 7.days.from_now.to_date)
  end

  def cancel!
    raise InvalidTransitionError, 'Delivered orders cannot be cancelled' if status == 'delivered'

    update!(status: 'cancelled')
  end

  def recalculate_total!
    update!(total_amount: line_items.sum(:total_price))
  end

  private

  def generate_number
    self.number ||= "ORD-#{SecureRandom.hex(4).upcase}"
  end
end
