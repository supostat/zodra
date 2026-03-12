# frozen_string_literal: true

module Zodra
  module Swagger
    class Engine < ::Rails::Engine
      isolate_namespace Zodra::Swagger
    end
  end
end

Zodra::Swagger::Engine.routes.draw do
  get 'specs/:slug', to: ->(env) { Zodra::Swagger.serve_spec(env) }, as: :spec
  root to: ->(env) { Zodra::Swagger.serve_index(env) }
end
