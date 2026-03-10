# frozen_string_literal: true

module Zodra
  class Action
    attr_reader :name, :params

    attr_accessor :http_method, :path, :response

    def initialize(name:)
      @name = name
      @params = Definition.new(name: :"#{name}_params", kind: :object)
    end
  end
end
