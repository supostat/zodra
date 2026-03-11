# frozen_string_literal: true

class Setting < ApplicationRecord
  validates :store_name, presence: true
  validates :currency, presence: true, length: { is: 3 }
  validates :timezone, presence: true

  def self.instance
    first || create!
  end
end
