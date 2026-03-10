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
  end
end
