# frozen_string_literal: true

RSpec.describe Zodra::Export::TypeScriptMapper do
  subject(:mapper) { described_class.new(key_format: :camel) }

  describe '#map_definitions' do
    it 'maps object type to interface' do
      definition = build_object(:invoice,
                                number: { type: :string },
                                amount: { type: :decimal, min: 0 },
                                paid: { type: :boolean, default: false })

      result = mapper.map_definition(definition)

      expect(result).to include('export interface Invoice {')
      expect(result).to include('  number: string;')
      expect(result).to include('  amount: number;')
      expect(result).to include('  paid: boolean;')
      expect(result).to include('}')
    end

    it 'maps enum to union of literals' do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent paid])

      result = mapper.map_definition(definition)

      expect(result).to eq("export type Status = 'draft' | 'sent' | 'paid';")
    end

    it 'maps union to discriminated union' do
      definition = Zodra::Definition.new(name: :payment_method, kind: :union, discriminator: :type)
      definition.add_variant(:card, attributes: {
                               last_four: Zodra::Attribute.new(name: :last_four, type: :string)
                             })
      definition.add_variant(:bank_transfer, attributes: {
                               account_number: Zodra::Attribute.new(name: :account_number, type: :string)
                             })

      result = mapper.map_definition(definition)

      expect(result).to include('export type PaymentMethod =')
      expect(result).to include("type: 'card'")
      expect(result).to include('lastFour: string')
      expect(result).to include("type: 'bank_transfer'")
      expect(result).to include('accountNumber: string')
    end

    it 'maps attribute enum to union of literals' do
      definition = build_object(:product,
                                currency: { type: :string, enum: %w[USD EUR GBP] })

      result = mapper.map_definition(definition)

      expect(result).to include("currency: 'USD' | 'EUR' | 'GBP';")
    end

    it 'maps enum ref to type name' do
      definition = build_object(:order,
                                status: { type: :string, enum_type_name: :order_status })

      result = mapper.map_definition(definition)

      expect(result).to include('  status: OrderStatus;')
    end

    it 'maps optional fields with ?' do
      definition = build_object(:profile,
                                name: { type: :string },
                                nickname: { type: :string, optional: true })

      result = mapper.map_definition(definition)

      expect(result).to include('  name: string;')
      expect(result).to include('  nickname?: string;')
    end

    it 'maps nullable fields with | null' do
      definition = build_object(:profile,
                                bio: { type: :string, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include('  bio: null | string;')
    end

    it 'maps reference to type name' do
      definition = build_object(:invoice,
                                customer: { type: :reference, reference_name: :customer })

      result = mapper.map_definition(definition)

      expect(result).to include('  customer: Customer;')
    end

    it 'maps nullable reference' do
      definition = build_object(:invoice,
                                payment: { type: :reference, reference_name: :payment_method, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include('  payment: PaymentMethod | null;')
    end

    it 'maps array of references' do
      definition = build_object(:invoice,
                                items: { type: :array, of: :item })

      result = mapper.map_definition(definition)

      expect(result).to include('  items: Item[];')
    end

    it 'maps array of primitives' do
      definition = build_object(:config,
                                tags: { type: :array, of: :string },
                                scores: { type: :array, of: :integer },
                                ratios: { type: :array, of: :decimal },
                                flags: { type: :array, of: :boolean })

      result = mapper.map_definition(definition)

      expect(result).to include('  tags: string[];')
      expect(result).to include('  scores: number[];')
      expect(result).to include('  ratios: number[];')
      expect(result).to include('  flags: boolean[];')
    end

    it 'maps uuid to string' do
      definition = build_object(:entity, id: { type: :uuid })

      result = mapper.map_definition(definition)

      expect(result).to include('  id: string;')
    end

    it 'applies camelCase key format' do
      definition = build_object(:user, first_name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).to include('  firstName: string;')
    end

    it 'uses as: alias for key name' do
      definition = build_object(:payrate,
                                pay_rate_guid: { type: :string, as: :payRateGUID })

      result = mapper.map_definition(definition)

      expect(result).to include('  payRateGUID: string;')
      expect(result).not_to include('payRateGuid')
    end
  end

  describe 'description and deprecated' do
    it 'adds JSDoc comment for type description' do
      definition = build_object(:product, name: { type: :string })
      definition.description = 'A product in the catalog'

      result = mapper.map_definition(definition)

      expect(result).to start_with("/** A product in the catalog */\n")
      expect(result).to include('export interface Product {')
    end

    it 'adds JSDoc comment for enum description' do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent])
      definition.description = 'Order status'

      result = mapper.map_definition(definition)

      expect(result).to start_with("/** Order status */\n")
    end

    it 'adds JSDoc comment for attribute description' do
      definition = build_object(:product,
                                name: { type: :string, description: 'Display name' })

      result = mapper.map_definition(definition)

      expect(result).to include("  /** Display name */\n  name: string;")
    end

    it 'adds @deprecated JSDoc tag for deprecated attribute' do
      definition = build_object(:product,
                                legacy_sku: { type: :string, deprecated: true })

      result = mapper.map_definition(definition)

      expect(result).to include("  /** @deprecated */\n  legacySku: string;")
    end

    it 'combines description and deprecated in JSDoc' do
      definition = build_object(:product,
                                old_code: { type: :string, description: 'Use sku instead', deprecated: true })

      result = mapper.map_definition(definition)

      expect(result).to include("  /** Use sku instead - @deprecated */\n  oldCode: string;")
    end

    it 'omits JSDoc when no description or deprecated' do
      definition = build_object(:product, name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).not_to include('/**')
    end
  end

  describe 'key_format :keep' do
    it 'preserves original keys' do
      keep_mapper = described_class.new(key_format: :keep)
      definition = build_object(:user, first_name: { type: :string })

      result = keep_mapper.map_definition(definition)

      expect(result).to include('  first_name: string;')
    end
  end

  describe '#map_contract' do
    it 'generates params interfaces with contract-scoped names' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.response_type = :invoice
        Zodra::TypeBuilder.new(action.params).instance_eval do
          string :number, min: 1
          decimal :amount, min: 0
        end
      end

      result = mapper.map_contract(contract)

      expect(result).to include('export interface CreateInvoicesParams {')
      expect(result).to include('  number: string;')
      expect(result).to include('  amount: number;')
    end

    it 'generates contract descriptor interface with response' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.response_type = :invoice
      end

      result = mapper.map_contract(contract)

      expect(result).to include('export interface InvoicesContract {')
      expect(result).to include("create: { method: 'POST'; path: '/invoices'; params: CreateInvoicesParams; response: Invoice };")
    end

    it 'omits response when not set' do
      contract = build_contract(:search) do |c|
        action = c.add_action(:query)
        action.http_method = :get
        action.path = '/search'
      end

      result = mapper.map_contract(contract)

      expect(result).to include("query: { method: 'GET'; path: '/search'; params: QuerySearchParams };")
      expect(result).not_to include('response:')
    end

    it 'includes collection flag for collection actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:index)
        action.http_method = :get
        action.path = '/products'
        action.response_type = :product
        action.collection!
      end

      result = mapper.map_contract(contract)

      expect(result).to include('response: Product; collection: true')
    end

    it 'omits collection flag for non-collection actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/products/:id'
        action.response_type = :product
      end

      result = mapper.map_contract(contract)

      expect(result).not_to include('collection')
    end

    it 'generates inline response interface for actions with response block' do
      contract = build_contract(:dashboard) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/dashboard'
        Zodra::TypeBuilder.new(action.response_definition).instance_eval do
          reference :overview, to: :dashboard_overview
          array :top_products, of: :top_product
        end
      end

      result = mapper.map_contract(contract)

      expect(result).to include('export interface ShowDashboardResponse {')
      expect(result).to include('  overview: DashboardOverview;')
      expect(result).to include('  topProducts: TopProduct[];')
    end

    it 'references inline response type in contract descriptor' do
      contract = build_contract(:dashboard) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/dashboard'
        Zodra::TypeBuilder.new(action.response_definition).instance_eval do
          string :title
        end
      end

      result = mapper.map_contract(contract)

      expect(result).to include('response: ShowDashboardResponse')
    end

    it 'generates empty interface for contract without actions' do
      contract = Zodra::Contract.new(name: :empty)

      result = mapper.map_contract(contract)

      expect(result).to eq('export interface EmptyContract {}')
    end
  end

  private

  def build_object(name, **attrs)
    definition = Zodra::Definition.new(name:, kind: :object)
    attrs.each do |attr_name, options|
      definition.add_attribute(attr_name, **options)
    end
    definition
  end

  def build_contract(name)
    contract = Zodra::Contract.new(name:)
    yield contract if block_given?
    contract
  end
end
