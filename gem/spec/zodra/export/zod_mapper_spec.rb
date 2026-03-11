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

    it 'maps array of references' do
      definition = build_object(:invoice, items: { type: :array, of: :item })

      result = mapper.map_definition(definition)

      expect(result).to include('items: z.array(ItemSchema)')
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
