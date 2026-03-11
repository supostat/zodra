# frozen_string_literal: true

Zodra.api "/api/v1" do
  resources :products
  resources :customers

  resources :orders, only: %i[index show create] do
    member do
      patch :confirm
      patch :cancel
    end
    collection do
      get :search
    end
  end

  resource :settings, only: %i[show update]
end
