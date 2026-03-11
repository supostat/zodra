# frozen_string_literal: true

module Zodra
  class Resource
    CRUD_ACTIONS = {
      index: { http_method: :get, member: false },
      show: { http_method: :get, member: true },
      create: { http_method: :post, member: false },
      update: { http_method: :patch, member: true },
      destroy: { http_method: :delete, member: true }
    }.freeze

    attr_reader :name, :singular, :contract_name, :controller_name,
                :custom_actions, :children, :only, :except

    def initialize(name:, singular: false, contract: nil, controller: nil, only: nil, except: nil)
      @name = name.to_sym
      @singular = singular
      @contract_name = contract&.to_sym || @name
      @controller_name = controller
      @only = only&.map(&:to_sym)
      @except = except&.map(&:to_sym)
      @custom_actions = []
      @children = []
    end

    def singular?
      @singular
    end

    def crud_actions
      actions = CRUD_ACTIONS.keys
      actions -= [:index] if singular?
      actions &= @only if @only
      actions -= @except if @except
      actions
    end

    def add_member_action(http_method, action_name)
      @custom_actions << { name: action_name.to_sym, http_method: http_method.to_sym, member: true }
    end

    def add_collection_action(http_method, action_name)
      @custom_actions << { name: action_name.to_sym, http_method: http_method.to_sym, member: false }
    end

    def add_child(resource)
      @children << resource
    end
  end
end
