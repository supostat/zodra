# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.text :notes
      t.datetime :registered_at, null: false

      t.timestamps
    end

    add_index :customers, :email, unique: true
  end
end
