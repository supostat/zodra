# frozen_string_literal: true

Zodra.union :payment_method, discriminator: :type do
  variant :card do
    string :last_four, min: 4, max: 4
    string :brand
    string :expiry_month, min: 2, max: 2
    string :expiry_year, min: 4, max: 4
  end
  variant :bank_transfer do
    string :bank_name
    string :account_last_four, min: 4, max: 4
  end
end
