# frozen_string_literal: true

module Api
  module V1
    class ProductsController < ApplicationController
      include Zodra::Controller

      def index
        products = Product.all
        zodra_respond_collection(products)
      end

      def show
        product = Product.find(zodra_params[:id])
        zodra_respond(product)
      end

      def create
        product = Product.new(zodra_params)

        if product.save
          zodra_respond(product, status: :created)
        else
          zodra_errors(product.errors)
        end
      end

      def update
        product = Product.find(zodra_params[:id])
        product.assign_attributes(zodra_params.except(:id))

        if product.save
          zodra_respond(product)
        else
          zodra_errors(product.errors)
        end
      end

      def destroy
        product = Product.find(zodra_params[:id])
        product.destroy!
        head :no_content
      end
    end
  end
end
