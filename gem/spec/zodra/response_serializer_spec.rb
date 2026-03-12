# frozen_string_literal: true

require 'ostruct'

RSpec.describe Zodra::ResponseSerializer do
  before { Zodra.configuration.key_format = :keep }

  after do
    Zodra::TypeRegistry.global.clear!
    Zodra.configuration.key_format = :camel
  end

  describe '.call' do
    it 'serializes object with primitive attributes' do
      definition = build_definition(
        name: { type: :string },
        amount: { type: :decimal }
      )
      object = OpenStruct.new(name: 'INV-1', amount: 100)

      result = described_class.call(object, definition)

      expect(result).to eq({ 'name' => 'INV-1', 'amount' => 100 })
    end

    it 'serializes hash with symbol keys' do
      definition = build_definition(name: { type: :string })

      result = described_class.call({ name: 'John' }, definition)

      expect(result).to eq({ 'name' => 'John' })
    end

    it 'serializes hash with string keys' do
      definition = build_definition(name: { type: :string })

      result = described_class.call({ 'name' => 'John' }, definition)

      expect(result).to eq({ 'name' => 'John' })
    end

    it 'applies camelCase key format' do
      definition = build_definition(
        first_name: { type: :string },
        last_name: { type: :string }
      )
      object = OpenStruct.new(first_name: 'John', last_name: 'Doe')

      result = described_class.call(object, definition, key_format: :camel)

      expect(result).to eq({ 'firstName' => 'John', 'lastName' => 'Doe' })
    end

    it 'serializes referenced types' do
      Zodra.type :customer do
        string :name
        string :email
      end

      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:total, type: :decimal)
      definition.add_attribute(:customer, type: :reference, reference_name: :customer)

      invoice = OpenStruct.new(
        total: 200,
        customer: OpenStruct.new(name: 'Acme', email: 'acme@example.com')
      )

      result = described_class.call(invoice, definition)

      expect(result['total']).to eq(200)
      expect(result['customer']).to eq({ 'name' => 'Acme', 'email' => 'acme@example.com' })
    end

    it 'serializes nil reference as nil' do
      Zodra.type :customer do
        string :name
      end

      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:customer, type: :reference, reference_name: :customer)

      result = described_class.call(OpenStruct.new(customer: nil), definition)

      expect(result['customer']).to be_nil
    end

    it 'serializes array of referenced types' do
      Zodra.type :line_item do
        string :description
        decimal :price
      end

      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:items, type: :array, of: :line_item)

      invoice = OpenStruct.new(
        items: [
          OpenStruct.new(description: 'Widget', price: 10),
          OpenStruct.new(description: 'Gadget', price: 20)
        ]
      )

      result = described_class.call(invoice, definition)

      expect(result['items']).to eq([
                                      { 'description' => 'Widget', 'price' => 10 },
                                      { 'description' => 'Gadget', 'price' => 20 }
                                    ])
    end

    it 'serializes array of primitives' do
      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:tags, type: :array, of: :string)

      result = described_class.call(OpenStruct.new(tags: %w[ruby rails]), definition)

      expect(result['tags']).to eq(%w[ruby rails])
    end

    it 'serializes nil array as empty array' do
      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:items, type: :array, of: :string)

      result = described_class.call(OpenStruct.new(items: nil), definition)

      expect(result['items']).to eq([])
    end

    it 'preserves false values from hash' do
      definition = build_definition(active: { type: :boolean })

      result = described_class.call({ active: false }, definition)

      expect(result['active']).to be(false)
    end

    it 'preserves false values from hash with string keys' do
      definition = build_definition(active: { type: :boolean })

      result = described_class.call({ 'active' => false }, definition)

      expect(result['active']).to be(false)
    end

    it 'uses as: alias for key name' do
      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:pay_rate_guid, type: :string, as: :payRateGUID)

      result = described_class.call(OpenStruct.new(pay_rate_guid: 'abc-123'), definition)

      expect(result).to eq({ 'payRateGUID' => 'abc-123' })
    end

    it 'uses as: alias over key_format' do
      definition = Zodra::Definition.new(name: :response, kind: :object)
      definition.add_attribute(:pay_rate_guid, type: :string, as: :payRateGUID)

      result = described_class.call(OpenStruct.new(pay_rate_guid: 'abc-123'), definition, key_format: :camel)

      expect(result).to eq({ 'payRateGUID' => 'abc-123' })
    end

    it 'only includes attributes defined in schema' do
      definition = build_definition(name: { type: :string })
      object = OpenStruct.new(name: 'John', secret: 'hidden')

      result = described_class.call(object, definition)

      expect(result.keys).to eq(['name'])
    end
  end

  private

  def build_definition(**attrs)
    definition = Zodra::Definition.new(name: :test, kind: :object)
    attrs.each { |attr_name, options| definition.add_attribute(attr_name, **options) }
    definition
  end
end
