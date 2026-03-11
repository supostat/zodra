# frozen_string_literal: true

Zodra.contract :settings do
  action :show do
    response do
      string :store_name
      string :currency
      string :timezone
      boolean :maintenance_mode
    end
  end

  action :update do
    params do
      string? :store_name, min: 1
      string? :currency, min: 3, max: 3
      string? :timezone
      boolean? :maintenance_mode
    end
    response do
      string :store_name
      string :currency
      string :timezone
      boolean :maintenance_mode
    end
  end
end
