# frozen_string_literal: true

module Zodra
  class Contract
    attr_reader :name, :actions, :types

    def initialize(name:)
      @name = name
      @actions = {}
      @types = TypeRegistry.new
    end

    def add_action(action_name)
      action = Action.new(name: action_name, contract: self)
      @actions[action_name.to_sym] = action
      action
    end

    def find_action(action_name)
      @actions[action_name.to_sym]
    end

    def resolve_type(type_name)
      types.find(type_name) || TypeRegistry.global.find!(type_name)
    end

    alias_method :find!, :resolve_type

    def find(type_name)
      types.find(type_name) || TypeRegistry.global.find(type_name)
    end
  end
end
