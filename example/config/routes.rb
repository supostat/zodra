# frozen_string_literal: true

Rails.application.routes.draw do
  mount Zodra::Swagger::Engine => '/docs'

  zodra_routes

  root "pages#index"
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api", "/admin") }

  get "up" => "rails/health#show", as: :rails_health_check
end
