# frozen_string_literal: true

Zodra.contract :products do
  action :index do
    description "List all products with pagination"
    response :product, collection: true
  end

  action :show do
    description "Get a single product by ID"
    params do
      uuid :id
    end
    response :product
  end

  action :create do
    description "Create a new product"
    params do
      string :name, min: 1
      string :sku, min: 1
      money :price, min: 0
      integer :stock, min: 0
      boolean :published, default: false
    end
    response :product

    errors do
      from_params
      key :base
    end
  end

  action :update do
    description "Update an existing product"
    params do
      uuid :id
      string? :name, min: 1
      string? :sku, min: 1
      decimal? :price, min: 0
      integer? :stock, min: 0
      boolean? :published
    end
    response :product

    errors do
      from_params
      key :base
    end
  end

  action :destroy do
    description "Delete a product"
    params do
      uuid :id
    end
  end

  action :legacy_search do
    deprecated! "Use :index with filter params instead"
    params do
      string? :query
    end
    response :product, collection: true
  end
end
