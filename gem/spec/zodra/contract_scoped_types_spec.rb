# frozen_string_literal: true

RSpec.describe 'Contract-scoped types' do
  before do
    Zodra::ContractRegistry.global.clear!
    Zodra::TypeRegistry.global.clear!
  end

  it 'defines types scoped to a contract' do
    contract = Zodra.contract :invoices do
      type :invoice do
        string :number
        decimal :amount
      end
    end

    expect(contract.types.find(:invoice)).not_to be_nil
    expect(contract.types.find(:invoice).attributes.keys).to eq(%i[number amount])
  end

  it 'does not leak contract types to global registry' do
    Zodra.contract :invoices do
      type :invoice do
        string :number
      end
    end

    expect(Zodra::TypeRegistry.global.find(:invoice)).to be_nil
  end

  it 'resolves contract-scoped types first' do
    Zodra.type :invoice do
      string :global_field
    end

    contract = Zodra.contract :invoices do
      type :invoice do
        string :scoped_field
      end
    end

    resolved = contract.resolve_type(:invoice)
    expect(resolved.attributes.keys).to eq([:scoped_field])
  end

  it 'falls back to global types' do
    Zodra.enum :currency, values: %i[USD EUR]

    contract = Zodra.contract :invoices do
      type :invoice do
        string :number
      end
    end

    resolved = contract.resolve_type(:currency)
    expect(resolved.values).to eq(%i[USD EUR])
  end

  it 'raises when type not found in either scope' do
    contract = Zodra.contract :invoices

    expect { contract.resolve_type(:nonexistent) }.to raise_error(KeyError)
  end

  it 'defines enums scoped to a contract' do
    contract = Zodra.contract :invoices do
      enum :status, values: %i[draft sent paid]
    end

    resolved = contract.types.find(:status)
    expect(resolved.enum?).to be true
    expect(resolved.values).to eq(%i[draft sent paid])
  end

  it 'defines unions scoped to a contract' do
    contract = Zodra.contract :payments do
      union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank do
          string :account
        end
      end
    end

    resolved = contract.types.find(:payment_method)
    expect(resolved.union?).to be true
    expect(resolved.variants.size).to eq(2)
  end
end
