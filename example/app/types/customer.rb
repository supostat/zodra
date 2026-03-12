# frozen_string_literal: true

Zodra.type :customer do
  description "A registered customer"

  uuid :id
  string :name
  string :email, description: "Primary contact email"
  string? :phone
  string :notes, nullable: true
  datetime :registered_at
  timestamps
end
