# frozen_string_literal: true

module Api
  module V1
    class CustomersController < ApplicationController
      include Zodra::Controller

      zodra_contract :customers

      def index
        customers = Customer.all
        zodra_respond_collection(customers)
      end

      def show
        customer = Customer.find(zodra_params[:id])
        zodra_respond(customer)
      end

      def create
        customer = Customer.create!(zodra_params)
        zodra_respond(customer, status: :created)
      end

      def update
        customer = Customer.find(zodra_params[:id])
        customer.update!(zodra_params.except(:id))
        zodra_respond(customer)
      end

      def destroy
        customer = Customer.find(zodra_params[:id])
        customer.destroy!
        head :no_content
      end
    end
  end
end
