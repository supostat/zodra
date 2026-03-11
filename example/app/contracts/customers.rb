# frozen_string_literal: true

Zodra.contract :customers do
  action :index do
    response :customer_summary, collection: true
  end

  action :show do
    params do
      uuid :id
    end
    response :customer
  end

  action :create do
    params from: :customer, omit: %i[id registered_at created_at updated_at]
    response :customer
  end

  action :update do
    params from: :customer, omit: %i[id registered_at created_at updated_at], partial: true
    response :customer
  end

  action :destroy do
    params do
      uuid :id
    end
  end
end
