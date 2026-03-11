# frozen_string_literal: true

RSpec.describe Zodra::TypeRegistry do
  subject(:registry) { described_class.new }

  after { registry.clear! }

  describe '#register' do
    it 'registers an object type' do
      registry.register(:invoice, kind: :object)

      expect(registry.exists?(:invoice)).to be true
    end

    it 'registers an enum type' do
      registry.register(:status, kind: :enum, values: %i[draft sent paid])

      definition = registry.find!(:status)
      expect(definition.kind).to eq(:enum)
      expect(definition.values).to eq(%i[draft sent paid])
    end

    it 'registers a union type' do
      registry.register(:payment_method, kind: :union, discriminator: :type)

      definition = registry.find!(:payment_method)
      expect(definition.kind).to eq(:union)
      expect(definition.discriminator).to eq(:type)
    end

    it 'raises on duplicate registration' do
      registry.register(:invoice, kind: :object)

      expect { registry.register(:invoice, kind: :object) }
        .to raise_error(Zodra::DuplicateTypeError, /invoice/)
    end
  end

  describe '#find / #find!' do
    it 'returns nil for missing type' do
      expect(registry.find(:missing)).to be_nil
    end

    it 'raises KeyError for missing type with find!' do
      expect { registry.find!(:missing) }
        .to raise_error(KeyError, /missing/)
    end

    it 'returns registered definition' do
      registry.register(:invoice, kind: :object)

      definition = registry.find!(:invoice)
      expect(definition.name).to eq(:invoice)
      expect(definition.kind).to eq(:object)
    end
  end

  describe '#each' do
    it 'iterates over all registered types' do
      registry.register(:invoice, kind: :object)
      registry.register(:status, kind: :enum, values: %i[draft sent])

      names = registry.each.map(&:name)
      expect(names).to contain_exactly(:invoice, :status)
    end
  end

  describe '#clear!' do
    it 'removes all registered types' do
      registry.register(:invoice, kind: :object)
      registry.clear!

      expect(registry.exists?(:invoice)).to be false
    end
  end
end
