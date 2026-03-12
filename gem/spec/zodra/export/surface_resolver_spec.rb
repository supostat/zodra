# frozen_string_literal: true

RSpec.describe Zodra::Export::SurfaceResolver do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  after do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  def all_definitions
    Zodra::TypeRegistry.global.to_a
  end

  def all_contracts
    Zodra::ContractRegistry.global.to_a
  end

  describe '.call' do
    it 'returns all definitions when no contracts exist' do
      Zodra.type(:customer) { string :name }
      Zodra.type(:invoice) { string :number }

      result = described_class.call(all_definitions, [])

      expect(result.map(&:name)).to contain_exactly(:customer, :invoice)
    end

    it 'filters to types reachable from contract response' do
      Zodra.type(:customer) { string :name }
      Zodra.type(:invoice) { string :number }
      Zodra.type(:unused) { string :data }

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:invoice)
    end

    it 'follows reference dependencies recursively' do
      Zodra.type(:address) { string :city }
      Zodra.type(:customer) do
        string :name
        reference :address
      end
      Zodra.type(:invoice) do
        reference :customer
      end
      Zodra.type(:unused) { string :data }

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:invoice, :customer, :address)
    end

    it 'follows array of dependencies' do
      Zodra.type(:item) { string :description }
      Zodra.type(:invoice) do
        string :number
        array :items, of: :item
      end

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:invoice, :item)
    end

    it 'collects types from params references' do
      Zodra.type(:filter) { string :query }
      Zodra.type(:invoice) { string :number }

      Zodra.contract :invoices do
        action :index do
          params { reference :filter }
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to include(:filter)
    end

    it 'collects types from inline response definitions' do
      Zodra.type(:customer) { string :name }
      Zodra.type(:unused) { string :data }

      Zodra.contract :customers do
        action :show do
          params { uuid :id }
          response do
            reference :customer
          end
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:customer)
    end

    it 'includes source type from params with from:' do
      Zodra.type(:order_input) do
        string :shipping_address
        array :items, of: :order_item_input
      end
      Zodra.type(:order_item_input) { uuid :product_id }
      Zodra.type(:order) { string :number }
      Zodra.type(:unused) { string :data }

      Zodra.contract :orders do
        action :create do
          params from: :order_input
          response :order
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:order_input, :order_item_input, :order)
    end

    it 'preserves original definition order' do
      Zodra.type(:address) { string :city }
      Zodra.type(:customer) do
        string :name
        reference :address
      end
      Zodra.type(:invoice) { reference :customer }

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to eq(%i[address customer invoice])
    end

    it 'handles union types referenced from contracts' do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :cash
      end

      Zodra.type(:unused) { string :data }

      Zodra.contract :payments do
        action :create do
          params { string :amount }
          response :payment_method
        end
      end

      result = described_class.call(all_definitions, all_contracts)

      expect(result.map(&:name)).to contain_exactly(:payment_method)
    end
  end
end
