# frozen_string_literal: true

Zodra.contract :orders do
  action :index do
    response :order, collection: true
  end

  action :show do
    params do
      uuid :id
    end
    response :order
  end

  action :create do
    params from: :order_input
    response :order
    error :validation_failed, status: 422

    errors do
      key :base
      key :customer_id
      key :shipping_address
      key :items do
        key :product_id
        key :quantity
      end
    end
  end

  action :confirm do
    params do
      uuid :id
    end
    response :order
    error :not_found, status: 404
    error :invalid_transition, status: 422
  end

  action :cancel do
    params do
      uuid :id
    end
    response :order
    error :not_found, status: 404
    error :invalid_transition, status: 422
  end

  action :search do
    params do
      order_status? :status
      date? :from_date
      date? :to_date
    end
    response :order, collection: true
  end
end
