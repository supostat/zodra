# frozen_string_literal: true

Zodra.contract :products do
  action :index do
    response :product, collection: true
  end

  action :show do
    params do
      uuid :id
    end
    response :product
  end

  action :create do
    params do
      string :name, min: 1
      string :sku, min: 1
      money :price, min: 0
      integer :stock, min: 0
      boolean :published, default: false
    end
    response :product
  end

  action :update do
    params do
      uuid :id
      string? :name, min: 1
      string? :sku, min: 1
      decimal? :price, min: 0
      integer? :stock, min: 0
      boolean? :published
    end
    response :product
  end

  action :destroy do
    params do
      uuid :id
    end
  end
end
