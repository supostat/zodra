# frozen_string_literal: true

RSpec.describe Zodra::Export::TypeScriptMapper do
  subject(:mapper) { described_class.new(key_format: :camel) }

  describe "#map_definitions" do
    it "maps object type to interface" do
      definition = build_object(:invoice,
                                number: { type: :string },
                                amount: { type: :decimal, min: 0 },
                                paid: { type: :boolean, default: false })

      result = mapper.map_definition(definition)

      expect(result).to include("export interface Invoice {")
      expect(result).to include("  number: string;")
      expect(result).to include("  amount: number;")
      expect(result).to include("  paid: boolean;")
      expect(result).to include("}")
    end

    it "maps enum to union of literals" do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent paid])

      result = mapper.map_definition(definition)

      expect(result).to eq("export type Status = 'draft' | 'sent' | 'paid';")
    end

    it "maps union to discriminated union" do
      definition = Zodra::Definition.new(name: :payment_method, kind: :union, discriminator: :type)
      definition.add_variant(:card, attributes: {
                               last_four: Zodra::Attribute.new(name: :last_four, type: :string)
                             })
      definition.add_variant(:bank_transfer, attributes: {
                               account_number: Zodra::Attribute.new(name: :account_number, type: :string)
                             })

      result = mapper.map_definition(definition)

      expect(result).to include("export type PaymentMethod =")
      expect(result).to include("type: 'card'")
      expect(result).to include("lastFour: string")
      expect(result).to include("type: 'bank_transfer'")
      expect(result).to include("accountNumber: string")
    end

    it "maps optional fields with ?" do
      definition = build_object(:profile,
                                name: { type: :string },
                                nickname: { type: :string, optional: true })

      result = mapper.map_definition(definition)

      expect(result).to include("  name: string;")
      expect(result).to include("  nickname?: string;")
    end

    it "maps nullable fields with | null" do
      definition = build_object(:profile,
                                bio: { type: :string, nullable: true })

      result = mapper.map_definition(definition)

      expect(result).to include("  bio: null | string;")
    end

    it "maps reference to type name" do
      definition = build_object(:invoice,
                                customer: { type: :reference, reference_name: :customer })

      result = mapper.map_definition(definition)

      expect(result).to include("  customer: Customer;")
    end

    it "maps array of references" do
      definition = build_object(:invoice,
                                items: { type: :array, of: :item })

      result = mapper.map_definition(definition)

      expect(result).to include("  items: Item[];")
    end

    it "maps uuid to string" do
      definition = build_object(:entity, id: { type: :uuid })

      result = mapper.map_definition(definition)

      expect(result).to include("  id: string;")
    end

    it "applies camelCase key format" do
      definition = build_object(:user, first_name: { type: :string })

      result = mapper.map_definition(definition)

      expect(result).to include("  firstName: string;")
    end
  end

  describe "key_format :keep" do
    it "preserves original keys" do
      keep_mapper = described_class.new(key_format: :keep)
      definition = build_object(:user, first_name: { type: :string })

      result = keep_mapper.map_definition(definition)

      expect(result).to include("  first_name: string;")
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
