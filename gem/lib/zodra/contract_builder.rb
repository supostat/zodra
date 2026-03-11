# frozen_string_literal: true

module Zodra
  class ContractBuilder
    def initialize(contract)
      @contract = contract
    end

    def action(name, &block)
      action = @contract.add_action(name)
      ActionBuilder.new(action).instance_eval(&block) if block
      action
    end

    def type(name, &block)
      definition = @contract.types.register(name, kind: :object)
      TypeBuilder.new(definition).instance_eval(&block) if block
      definition
    end

    def enum(name, values:)
      @contract.types.register(name, kind: :enum, values:)
    end

    def union(name, discriminator:, &block)
      definition = @contract.types.register(name, kind: :union, discriminator:)
      UnionBuilder.new(definition).instance_eval(&block) if block
      definition
    end
  end
end
