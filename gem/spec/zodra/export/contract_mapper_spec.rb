# frozen_string_literal: true

RSpec.describe Zodra::Export::ContractMapper do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
    Zodra::ApiRegistry.global.clear!
  end

  def setup_invoices_contract
    Zodra.type :invoice do
      uuid :id
      string :number
      decimal :amount
    end

    contract = Zodra.contract :invoices do
      action :create do
        params do
          string :number, min: 1
          decimal :amount, min: 0
        end
        response :invoice
      end

      action :show do
        params do
          uuid :id
        end
        response :invoice
      end
    end

    contract.find_action(:create).tap do |a|
      a.http_method = :post
      a.path = '/invoices'
    end
    contract.find_action(:show).tap do |a|
      a.http_method = :get
      a.path = '/invoices/:id'
    end
  end

  describe '#generate' do
    it 'returns empty string when no contracts exist' do
      result = described_class.new([], []).generate

      expect(result).to eq('')
    end

    it 'generates contracts barrel with API definitions' do
      setup_invoices_contract
      Zodra.api '/api/v1' do
        resources :invoices
      end

      result = Zodra::Export.generate_contracts

      expect(result).to include("import { InvoicesContract } from './schemas';")
      expect(result).to include('export const contracts = {')
      expect(result).to include('invoices: InvoicesContract')
      expect(result).to include('} as const;')
      expect(result).to include("export const baseUrl = '/api/v1';")
    end

    it 'uses contract names from resources, not registry' do
      setup_invoices_contract

      Zodra.contract :unused_contract do
        action :search do
          params { string :q }
        end
      end

      Zodra.api '/api/v1' do
        resources :invoices
      end

      result = Zodra::Export.generate_contracts

      expect(result).to include('InvoicesContract')
      expect(result).not_to include('UnusedContract')
    end

    it 'handles custom contract name on resource' do
      setup_invoices_contract

      Zodra.api '/api/v1' do
        resources :bills, contract: :invoices
      end

      result = Zodra::Export.generate_contracts

      expect(result).to include('invoices: InvoicesContract')
    end

    it 'includes nested resources' do
      setup_invoices_contract

      Zodra.type :line_item do
        uuid :id
        string :description
      end

      contract = Zodra.contract :line_items do
        action :index do
          params { uuid :invoice_id }
          response :line_item
        end
      end

      contract.find_action(:index).tap do |a|
        a.http_method = :get
        a.path = '/invoices/:invoice_id/line_items'
      end

      Zodra.api '/api/v1' do
        resources :invoices do
          resources :line_items
        end
      end

      result = Zodra::Export.generate_contracts

      expect(result).to include('InvoicesContract')
      expect(result).to include('LineItemsContract')
      expect(result).to include('invoices: InvoicesContract')
      expect(result).to include('lineItems: LineItemsContract')
    end

    it 'falls back to all contracts when no API definitions' do
      setup_invoices_contract

      contracts = Zodra::ContractRegistry.global.to_a
      result = described_class.new([], contracts).generate

      expect(result).to include('InvoicesContract')
      expect(result).not_to include('baseUrl')
    end

    it 'omits baseUrl when no API definitions' do
      setup_invoices_contract

      contracts = Zodra::ContractRegistry.global.to_a
      result = described_class.new([], contracts).generate

      expect(result).not_to include('baseUrl')
    end

    it 'generates multiple contracts' do
      setup_invoices_contract

      Zodra.type :customer do
        uuid :id
        string :name
      end

      contract = Zodra.contract :customers do
        action :index do
          params {}
          response :customer
        end
      end

      contract.find_action(:index).tap do |a|
        a.http_method = :get
        a.path = '/customers'
      end

      Zodra.api '/api/v1' do
        resources :invoices
        resources :customers
      end

      result = Zodra::Export.generate_contracts

      expect(result).to include("import { InvoicesContract, CustomersContract } from './schemas';")
      expect(result).to include('invoices: InvoicesContract')
      expect(result).to include('customers: CustomersContract')
    end
  end
end
