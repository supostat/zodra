# frozen_string_literal: true

Rails.application.routes.draw do
  zodra_routes

  get "up" => "rails/health#show", as: :rails_health_check
end
