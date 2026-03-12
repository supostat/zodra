# frozen_string_literal: true

Rails.application.routes.draw do
  zodra_routes

  root "pages#index"
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api") }

  get "up" => "rails/health#show", as: :rails_health_check
end
