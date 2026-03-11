# frozen_string_literal: true

class Customer < ApplicationRecord
  before_create { self.id = SecureRandom.uuid if id.blank? }

  has_many :orders, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :registered_at, presence: true

  before_validation :set_registered_at, on: :create

  private

  def set_registered_at
    self.registered_at ||= Time.current
  end
end
