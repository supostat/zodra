# frozen_string_literal: true

# Example type definition — will be implemented with Zodra DSL
#
# Zodra.type :invoice do
#   uuid :id
#   string :number
#   decimal :amount, min: 0
#   enum :status, values: %i[draft sent paid overdue]
#   reference :customer
#   array :items, of: :item
#   timestamps
# end
