# frozen_string_literal: true

RSpec.describe Zodra::Export::ZodMapper do
  subject(:mapper) { described_class.new(key_format: :camel) }

  describe "#map_definition" do
    it "maps object type to z.object schema" do
      definition = build_object(:invoice,
                                number: { type: :string },
                                amount: { type: :decimal, min: 0 },
                                paid: { type: :boolean, default: false })

      result = mapper.map_definition(definition)

      expect(result).to include("export const InvoiceSchema = z.object({")
      expect(result).to include("  number: z.string(),")
      expect(result).to include("  amount: z.number().min(0),")
      expect(result).to include("  paid: z.boolean().default(false),")
      expect(result).to include("});")
    end

    it "maps enum to z.enum" do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent paid])

      result = mapper.map_definition(definition)

      expect(result).to eq("export const StatusSchema = z.enum(['draft', 'sent', 'paid']);")
    end

    it "maps union to z.discriminatedUnion" do
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
      expect(result).to include("lastFour: z.string()")
      expect(result).to include("z.literal('bank_transfer')")
      expect(result).to include("accountNumber: z.string()")
    end

    it "maps optional with .optional()" do
      definition = build_object(:profile, nickname: { type: :string, optional: true })

      result = mapper.map_definition(definition)

      expect(result).to include("nickname: z.string().optional()")
    end

    it "maps nullable with .nullable()" do
      definition = build_object(:profile, bio: { type: :string, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include("bio: z.string().nullable()")
    end

    it "maps uuid to z.string().uuid()" do
      definition = build_object(:entity, id: { type: :uuid })

      result = mapper.map_definition(definition)

      expect(result).to include("id: z.string().uuid()")
    end

    it "maps reference to schema name" do
      definition = build_object(:invoice, customer: { type: :reference, reference_name: :customer })

      result = mapper.map_definition(definition)

      expect(result).to include("customer: CustomerSchema")
    end

    it "maps array of references" do
      definition = build_object(:invoice, items: { type: :array, of: :item })

      result = mapper.map_definition(definition)

      expect(result).to include("items: z.array(ItemSchema)")
    end

    it "maps min/max constraints" do
      definition = build_object(:product,
                                name: { type: :string, min: 1, max: 100 },
                                price: { type: :decimal, min: 0 })

      result = mapper.map_definition(definition)

      expect(result).to include("name: z.string().min(1).max(100)")
      expect(result).to include("price: z.number().min(0)")
    end

    it "applies camelCase key format" do
      definition = build_object(:user, first_name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).to include("firstName: z.string()")
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
end
