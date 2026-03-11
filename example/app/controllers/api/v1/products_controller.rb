# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      include Zodra::Controller

      zodra_contract :products

      def index
        products = Product.all
        zodra_respond_collection(products)
      end

      def show
        product = Product.find(zodra_params[:id])
        zodra_respond(product)
      end

      def create
        product = Product.create!(zodra_params)
        zodra_respond(product, status: :created)
      end

      def update
        product = Product.find(zodra_params[:id])
        product.update!(zodra_params.except(:id))
        zodra_respond(product)
      end

      def destroy
        product = Product.find(zodra_params[:id])
        product.destroy!
        head :no_content
      end
    end
  end
end
