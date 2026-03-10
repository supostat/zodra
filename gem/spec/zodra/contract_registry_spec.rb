# frozen_string_literal: true

RSpec.describe Zodra::ContractRegistry do
  subject(:registry) { described_class.new }

  describe "#register" do
    it "registers a contract" do
      contract = registry.register(:invoices)

      expect(contract).to be_a(Zodra::Contract)
      expect(contract.name).to eq(:invoices)
    end

    it "raises on duplicate registration" do
      registry.register(:invoices)

      expect { registry.register(:invoices) }
        .to raise_error(Zodra::DuplicateTypeError, /invoices/)
    end
  end

  describe "#find / #find!" do
    before { registry.register(:invoices) }

    it "returns registered contract" do
      expect(registry.find(:invoices).name).to eq(:invoices)
    end

    it "returns nil for missing contract" do
      expect(registry.find(:unknown)).to be_nil
    end

    it "raises KeyError for missing contract with find!" do
      expect { registry.find!(:unknown) }.to raise_error(KeyError)
    end
  end

  describe "#each" do
    it "iterates over all registered contracts" do
      registry.register(:invoices)
      registry.register(:users)

      names = registry.map(&:name)
      expect(names).to contain_exactly(:invoices, :users)
    end
  end

  describe "#clear!" do
    it "removes all registered contracts" do
      registry.register(:invoices)
      registry.clear!

      expect(registry.exists?(:invoices)).to be false
    end
  end
end
