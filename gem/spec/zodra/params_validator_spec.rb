# frozen_string_literal: true

require 'bigdecimal'

RSpec.describe Zodra::ParamsValidator do
  describe '.call' do
    it 'returns empty hash for valid params' do
      schema = build_schema(name: { type: :string })
      errors = described_class.call({ name: 'John' }, schema:)

      expect(errors).to be_empty
    end

    it 'returns error for missing required param' do
      schema = build_schema(name: { type: :string })
      errors = described_class.call({}, schema:)

      expect(errors[:name]).to include('is required')
    end

    it 'skips required check for optional params' do
      schema = build_schema(name: { type: :string, optional: true })
      errors = described_class.call({}, schema:)

      expect(errors).to be_empty
    end

    it 'returns error for coercion failure' do
      schema = build_schema(age: { type: :integer })
      errors = described_class.call({ age: :coercion_error }, schema:)

      expect(errors[:age]).to include('is not a valid integer')
    end

    it 'validates string min length' do
      schema = build_schema(name: { type: :string, min: 3 })
      errors = described_class.call({ name: 'AB' }, schema:)

      expect(errors[:name]).to include('is too short (minimum is 3 characters)')
    end

    it 'validates string max length' do
      schema = build_schema(name: { type: :string, max: 5 })
      errors = described_class.call({ name: 'ABCDEF' }, schema:)

      expect(errors[:name]).to include('is too long (maximum is 5 characters)')
    end

    it 'validates numeric min value' do
      schema = build_schema(amount: { type: :decimal, min: 0 })
      errors = described_class.call({ amount: BigDecimal('-1') }, schema:)

      expect(errors[:amount]).to include('must be greater than or equal to 0')
    end

    it 'validates numeric max value' do
      schema = build_schema(quantity: { type: :integer, max: 100 })
      errors = described_class.call({ quantity: 101 }, schema:)

      expect(errors[:quantity]).to include('must be less than or equal to 100')
    end

    it 'allows nil for nullable params' do
      schema = build_schema(bio: { type: :string, nullable: true })
      errors = described_class.call({ bio: nil }, schema:)

      expect(errors).to be_empty
    end

    it 'returns error for nil on non-nullable param' do
      schema = build_schema(name: { type: :string })
      errors = described_class.call({ name: nil }, schema:)

      expect(errors[:name]).to include('is required')
    end

    it 'validates integer min/max as numeric' do
      schema = build_schema(page: { type: :integer, min: 1, max: 100 })
      errors = described_class.call({ page: 0 }, schema:)

      expect(errors[:page]).to include('must be greater than or equal to 1')
    end

    it 'validates number min/max as numeric' do
      schema = build_schema(price: { type: :number, min: 0.01 })
      errors = described_class.call({ price: 0.0 }, schema:)

      expect(errors[:price]).to include('must be greater than or equal to 0.01')
    end

    it 'validates enum inclusion' do
      schema = build_schema(currency: { type: :string, enum: %w[USD EUR GBP] })
      errors = described_class.call({ currency: 'JPY' }, schema:)

      expect(errors[:currency]).to include('is not included in the list')
    end

    it 'passes valid enum value' do
      schema = build_schema(currency: { type: :string, enum: %w[USD EUR GBP] })
      errors = described_class.call({ currency: 'USD' }, schema:)

      expect(errors).to be_empty
    end

    it 'validates enum ref inclusion' do
      Zodra::TypeRegistry.global.clear!
      Zodra.enum :priority, values: %i[low medium high]
      schema = build_schema(level: { type: :string, enum_type_name: :priority })
      errors = described_class.call({ level: 'critical' }, schema:)

      expect(errors[:level]).to include('is not included in the list')
    end

    it 'passes valid enum ref value' do
      Zodra::TypeRegistry.global.clear!
      Zodra.enum :priority, values: %i[low medium high]
      schema = build_schema(level: { type: :string, enum_type_name: :priority })
      errors = described_class.call({ level: 'high' }, schema:)

      expect(errors).to be_empty
    end

    it 'collects multiple errors per field' do
      schema = build_schema(name: { type: :string })
      errors = described_class.call({ name: :coercion_error }, schema:)

      expect(errors[:name]).to be_an(Array)
    end

    it 'skips constraint checks on coercion error' do
      schema = build_schema(name: { type: :string, min: 3 })
      errors = described_class.call({ name: :coercion_error }, schema:)

      expect(errors[:name]).to eq(['is not a valid string'])
    end

    it 'treats param with default: false as optional' do
      schema = build_schema(active: { type: :boolean, default: false })
      errors = described_class.call({}, schema:)

      expect(errors).to be_empty
    end

    it 'treats param with default: 0 as optional' do
      schema = build_schema(page: { type: :integer, default: 0 })
      errors = described_class.call({}, schema:)

      expect(errors).to be_empty
    end

    it 'skips absent optional param constraints' do
      schema = build_schema(nickname: { type: :string, optional: true, min: 2 })
      errors = described_class.call({}, schema:)

      expect(errors).to be_empty
    end
  end

  private

  def build_schema(**attrs)
    definition = Zodra::Definition.new(name: :test, kind: :object)
    attrs.each do |attr_name, options|
      definition.add_attribute(attr_name, **options)
    end
    definition
  end
end
