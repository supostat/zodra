# frozen_string_literal: true

Rails.application.routes.draw do
  mount Zodra::Swagger => '/docs'

  zodra_routes

  namespace :ssr do
    resource :dashboard, only: [:show]
    resources :products, only: %i[index show]
    resources :orders, only: %i[index show]
    resource :settings, only: [:show]
  end

  root "pages#index"
  get "*path", to: "pages#index", constraints: ->(req) { !req.path.start_with?("/api", "/ssr", "/docs") }

  get "up" => "rails/health#show", as: :rails_health_check
end
