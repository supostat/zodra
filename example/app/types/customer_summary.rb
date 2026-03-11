# frozen_string_literal: true

Zodra.type :customer_summary, from: :customer, pick: %i[id name email]
