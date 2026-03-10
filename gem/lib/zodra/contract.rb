# frozen_string_literal: true

module Zodra
  class Contract
    attr_reader :name, :actions

    def initialize(name:)
      @name = name
      @actions = {}
    end

    def add_action(action_name)
      action = Action.new(name: action_name)
      @actions[action_name.to_sym] = action
      action
    end

    def find_action(action_name)
      @actions[action_name.to_sym]
    end
  end
end
