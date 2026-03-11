# frozen_string_literal: true

Zodra.type :customer do
  uuid :id
  string :name
  string :email
  string? :phone
  string :notes, nullable: true
  datetime :registered_at
  timestamps
end
