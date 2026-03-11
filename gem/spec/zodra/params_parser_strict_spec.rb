# frozen_string_literal: true

RSpec.describe Zodra::ParamsParser, 'strict mode' do
  before { Zodra.configuration.strict_params = true }

  after { Zodra.configuration.strict_params = true }

  describe 'strict: true' do
    it 'returns error for unknown keys' do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ 'name' => 'John', 'admin' => 'true' }, schema:)

      expect(result).to be_invalid
      expect(result.errors[:admin]).to include('is not allowed')
    end

    it 'returns errors for multiple unknown keys' do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ 'name' => 'John', 'admin' => 'true', 'role' => 'superuser' }, schema:)

      expect(result.errors[:admin]).to include('is not allowed')
      expect(result.errors[:role]).to include('is not allowed')
    end

    it 'passes when all keys are known' do
      schema = build_schema(name: { type: :string }, age: { type: :integer })

      result = described_class.call({ 'name' => 'John', 'age' => '30' }, schema:)

      expect(result).to be_valid
    end

    it 'combines unknown key errors with validation errors' do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ 'admin' => 'true' }, schema:)

      expect(result.errors[:admin]).to include('is not allowed')
      expect(result.errors[:name]).to include('is required')
    end
  end

  describe 'strict: false' do
    it 'silently filters unknown keys' do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ 'name' => 'John', 'admin' => 'true' }, schema:, strict: false)

      expect(result).to be_valid
      expect(result.params.keys).to eq([:name])
    end
  end

  describe 'configuration default' do
    it 'uses configuration value' do
      Zodra.configuration.strict_params = false
      schema = build_schema(name: { type: :string })

      result = described_class.call({ 'name' => 'John', 'admin' => 'true' }, schema:)

      expect(result).to be_valid
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
