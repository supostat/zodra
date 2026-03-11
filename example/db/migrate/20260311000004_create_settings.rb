# frozen_string_literal: true

class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :store_name, null: false, default: 'Zodra Store'
      t.string :currency, null: false, default: 'USD'
      t.string :timezone, null: false, default: 'UTC'
      t.boolean :maintenance_mode, null: false, default: false

      t.timestamps
    end
  end
end
