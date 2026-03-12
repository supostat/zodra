# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders, id: :uuid do |t|
      t.string :number, null: false
      t.string :status, null: false, default: 'draft'
      t.references :customer, type: :uuid, null: false, foreign_key: true
      t.json :payment_method
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.string :shipping_address
      t.date :estimated_delivery

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
  end
end
