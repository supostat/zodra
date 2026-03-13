# frozen_string_literal: true

RSpec.describe Zodra::Export::ZodMapper do
  subject(:mapper) { described_class.new(key_format: :camel) }

  describe '#map_definition' do
    it 'maps object type to z.object schema' do
      definition = build_object(:invoice,
                                number: { type: :string },
                                amount: { type: :decimal, min: 0 },
                                paid: { type: :boolean, default: false })

      result = mapper.map_definition(definition)

      expect(result).to include('export const InvoiceSchema = z.object({')
      expect(result).to include('  number: z.string(),')
      expect(result).to include('  amount: z.number().min(0),')
      expect(result).to include('  paid: z.boolean().default(false),')
      expect(result).to include('});')
    end

    it 'maps enum to z.enum' do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent paid])

      result = mapper.map_definition(definition)

      expect(result).to eq("export const StatusSchema = z.enum(['draft', 'sent', 'paid']);")
    end

    it 'maps union to z.discriminatedUnion' do
      definition = Zodra::Definition.new(name: :payment_method, kind: :union, discriminator: :type)
      definition.add_variant(:card, attributes: {
                               last_four: Zodra::Attribute.new(name: :last_four, type: :string)
                             })
      definition.add_variant(:bank_transfer, attributes: {
                               account_number: Zodra::Attribute.new(name: :account_number, type: :string)
                             })

      result = mapper.map_definition(definition)

      expect(result).to include("export const PaymentMethodSchema = z.discriminatedUnion('type', [")
      expect(result).to include("z.literal('card')")
      expect(result).to include('lastFour: z.string()')
      expect(result).to include("z.literal('bank_transfer')")
      expect(result).to include('accountNumber: z.string()')
    end

    it 'maps optional with .optional()' do
      definition = build_object(:profile, nickname: { type: :string, optional: true })

      result = mapper.map_definition(definition)

      expect(result).to include('nickname: z.string().optional()')
    end

    it 'maps nullable with .nullable()' do
      definition = build_object(:profile, bio: { type: :string, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include('bio: z.string().nullable()')
    end

    it 'maps uuid to z.uuid()' do
      definition = build_object(:entity, id: { type: :uuid })

      result = mapper.map_definition(definition)

      expect(result).to include('id: z.uuid()')
    end

    it 'maps reference to schema name' do
      definition = build_object(:invoice, customer: { type: :reference, reference_name: :customer })

      result = mapper.map_definition(definition)

      expect(result).to include('customer: CustomerSchema')
    end

    it 'maps nullable reference with .nullable()' do
      definition = build_object(:invoice, payment: { type: :reference, reference_name: :payment_method, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include('payment: PaymentMethodSchema.nullable()')
    end

    it 'maps array of references' do
      definition = build_object(:invoice, items: { type: :array, of: :item })

      result = mapper.map_definition(definition)

      expect(result).to include('items: z.array(ItemSchema)')
    end

    it 'maps array of primitives' do
      definition = build_object(:config,
                                tags: { type: :array, of: :string },
                                scores: { type: :array, of: :integer },
                                ratios: { type: :array, of: :decimal },
                                flags: { type: :array, of: :boolean })

      result = mapper.map_definition(definition)

      expect(result).to include('tags: z.array(z.string())')
      expect(result).to include('scores: z.array(z.number().int())')
      expect(result).to include('ratios: z.array(z.number())')
      expect(result).to include('flags: z.array(z.boolean())')
    end

    it 'maps attribute enum to z.enum' do
      definition = build_object(:product,
                                currency: { type: :string, enum: %w[USD EUR GBP] })

      result = mapper.map_definition(definition)

      expect(result).to include("currency: z.enum(['USD', 'EUR', 'GBP'])")
    end

    it 'maps enum ref to schema reference' do
      definition = build_object(:order,
                                status: { type: :string, enum_type_name: :order_status })

      result = mapper.map_definition(definition)

      expect(result).to include('status: OrderStatusSchema')
    end

    it 'maps min/max constraints' do
      definition = build_object(:product,
                                name: { type: :string, min: 1, max: 100 },
                                price: { type: :decimal, min: 0 })

      result = mapper.map_definition(definition)

      expect(result).to include('name: z.string().min(1).max(100)')
      expect(result).to include('price: z.number().min(0)')
    end

    it 'applies camelCase key format' do
      definition = build_object(:user, first_name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).to include('firstName: z.string()')
    end

    it 'uses as: alias for key name' do
      definition = build_object(:payrate,
                                pay_rate_guid: { type: :string, as: :payRateGUID })

      result = mapper.map_definition(definition)

      expect(result).to include('payRateGUID: z.string()')
      expect(result).not_to include('payRateGuid')
    end
  end

  describe 'description and deprecated' do
    it 'adds .describe() for type description' do
      definition = build_object(:product, name: { type: :string })
      definition.description = 'A product in the catalog'

      result = mapper.map_definition(definition)

      expect(result).to include("}).describe('A product in the catalog');")
    end

    it 'adds .describe() for enum description' do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent])
      definition.description = 'Order status'

      result = mapper.map_definition(definition)

      expect(result).to include(".describe('Order status');")
    end

    it 'adds .describe() for attribute description' do
      definition = build_object(:product,
                                name: { type: :string, description: 'Display name' })

      result = mapper.map_definition(definition)

      expect(result).to include("name: z.string().describe('Display name')")
    end

    it 'adds .describe(@deprecated) for deprecated attribute' do
      definition = build_object(:product,
                                legacy_sku: { type: :string, deprecated: true })

      result = mapper.map_definition(definition)

      expect(result).to include("legacySku: z.string().describe('@deprecated')")
    end

    it 'combines description and deprecated in .describe()' do
      definition = build_object(:product,
                                old_code: { type: :string, description: 'Use sku instead', deprecated: true })

      result = mapper.map_definition(definition)

      expect(result).to include("oldCode: z.string().describe('Use sku instead - @deprecated')")
    end

    it 'escapes single quotes in description' do
      definition = build_object(:product,
                                name: { type: :string, description: "it's a name" })

      result = mapper.map_definition(definition)

      expect(result).to include("name: z.string().describe('it\\'s a name')")
    end

    it 'omits .describe() when no description or deprecated' do
      definition = build_object(:product, name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).not_to include('describe')
    end
  end

  describe '#map_contract' do
    it 'generates params schemas with contract-scoped names' do
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

      expect(result).to include('export const CreateInvoicesParamsSchema = z.object({')
      expect(result).to include('number: z.string().min(1)')
      expect(result).to include('amount: z.number().min(0)')
    end

    it 'generates contract descriptor with response' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.response_type = :invoice
      end

      result = mapper.map_contract(contract)

      expect(result).to include('export const InvoicesContract = {')
      expect(result).to include("create: { method: 'POST' as const, path: '/invoices' as const, params: CreateInvoicesParamsSchema, response: InvoiceSchema }")
      expect(result).to include('} as const;')
    end

    it 'omits response when not set' do
      contract = build_contract(:search) do |c|
        action = c.add_action(:query)
        action.http_method = :get
        action.path = '/search'
      end

      result = mapper.map_contract(contract)

      expect(result).to include("query: { method: 'GET' as const, path: '/search' as const, params: QuerySearchParamsSchema }")
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

      expect(result).to include('response: ProductSchema, collection: true as const')
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

    it 'generates empty descriptor for contract without actions' do
      contract = Zodra::Contract.new(name: :empty)

      result = mapper.map_contract(contract)

      expect(result).to eq('export const EmptyContract = {} as const;')
    end

    it 'generates business error types for actions with errors' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.response_type = :invoice
        action.add_error(:already_finalized, status: 409)
        action.add_error(:insufficient_balance, status: 422)
      end

      result = mapper.map_contract(contract)

      expect(result).to include("export type CreateInvoicesBusinessError = { code: 'already_finalized' | 'insufficient_balance'; message: string };")
    end

    it 'includes errors in contract descriptor' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.add_error(:already_finalized, status: 409)
      end

      result = mapper.map_contract(contract)

      expect(result).to include("errors: [{ code: 'already_finalized' as const, status: 409 as const }] as const")
    end

    it 'generates inline response schema for actions with response block' do
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

      expect(result).to include('export const ShowDashboardResponseSchema = z.object({')
      expect(result).to include('overview: DashboardOverviewSchema')
      expect(result).to include('topProducts: z.array(TopProductSchema)')
    end

    it 'references inline response schema in contract descriptor' do
      contract = build_contract(:dashboard) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/dashboard'
        Zodra::TypeBuilder.new(action.response_definition).instance_eval do
          string :title
        end
      end

      result = mapper.map_contract(contract)

      expect(result).to include('response: ShowDashboardResponseSchema')
    end

    it 'skips error types for actions without errors' do
      contract = build_contract(:search) do |c|
        action = c.add_action(:query)
        action.http_method = :get
        action.path = '/search'
      end

      result = mapper.map_contract(contract)

      expect(result).not_to include('BusinessError')
      expect(result).not_to include('errors:')
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
