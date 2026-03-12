# frozen_string_literal: true

RSpec.describe Zodra::Contract do
  subject(:contract) { described_class.new(name: :invoices) }

  describe '#add_action' do
    it 'adds an action to the contract' do
      action = contract.add_action(:create)

      expect(action).to be_a(Zodra::Action)
      expect(action.name).to eq(:create)
      expect(contract.actions.size).to eq(1)
    end
  end

  describe '#find_action' do
    it 'returns action by name' do
      contract.add_action(:create)

      expect(contract.find_action(:create).name).to eq(:create)
    end

    it 'returns nil for missing action' do
      expect(contract.find_action(:unknown)).to be_nil
    end
  end

  describe '#openapi?' do
    it 'defaults to true' do
      expect(contract.openapi?).to be true
    end

    it 'can be disabled' do
      contract.openapi = false

      expect(contract.openapi?).to be false
    end
  end
end
