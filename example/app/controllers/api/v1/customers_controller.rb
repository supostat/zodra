# frozen_string_literal: true

module Api
  module V1
    class CustomersController < ApplicationController
      include Zodra::Controller

      def index
        customers = Customer.all
        zodra_respond_collection(customers)
      end

      def show
        customer = Customer.find(zodra_params[:id])
        zodra_respond(customer)
      end

      def create
        customer = Customer.new(zodra_params)

        if customer.save
          zodra_respond(customer, status: :created)
        else
          zodra_errors(customer.errors)
        end
      end

      def update
        customer = Customer.find(zodra_params[:id])
        customer.assign_attributes(zodra_params.except(:id))

        if customer.save
          zodra_respond(customer)
        else
          zodra_errors(customer.errors)
        end
      end

      def destroy
        customer = Customer.find(zodra_params[:id])
        customer.destroy!
        head :no_content
      end
    end
  end
end
