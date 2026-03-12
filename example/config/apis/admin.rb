# frozen_string_literal: true

Zodra.api "/admin" do
  resource :dashboard, only: [:show]
end
