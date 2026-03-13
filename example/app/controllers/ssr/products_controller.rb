# frozen_string_literal: true

module Ssr
  class ProductsController < BaseController
    def index
      products = Product.all
      @props = { products: zodra_serialize_many(products, :product) }
    end

    def show
      product = Product.find(params[:id])
      @props = { product: zodra_serialize(product, :product) }
    end
  end
end
