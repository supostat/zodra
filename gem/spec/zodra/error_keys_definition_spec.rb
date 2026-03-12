# frozen_string_literal: true

RSpec.describe Zodra::ErrorKeysDefinition do
  describe '#add_key' do
    it 'adds a flat key' do
      definition = described_class.new
      definition.add_key(:name)

      expect(definition.keys).to eq(name: nil)
    end

    it 'adds a key with children' do
      definition = described_class.new
      definition.add_key(:items, children: { starts_at: nil, ends_at: nil })

      expect(definition.keys).to eq(items: { starts_at: nil, ends_at: nil })
    end
  end

  describe '#flat_keys' do
    it 'returns top-level key names' do
      definition = described_class.new
      definition.add_key(:base)
      definition.add_key(:name)
      definition.add_key(:items, children: { text: nil })

      expect(definition.flat_keys).to eq(%i[base name items])
    end
  end

  describe '#children_for' do
    it 'returns nil for flat keys' do
      definition = described_class.new
      definition.add_key(:name)

      expect(definition.children_for(:name)).to be_nil
    end

    it 'returns children hash for nested keys' do
      definition = described_class.new
      definition.add_key(:items, children: { text: nil })

      expect(definition.children_for(:items)).to eq(text: nil)
    end
  end

  describe '#empty?' do
    it 'returns true when no keys' do
      expect(described_class.new).to be_empty
    end

    it 'returns false when keys exist' do
      definition = described_class.new
      definition.add_key(:name)

      expect(definition).not_to be_empty
    end
  end

  describe '#add_keys_from_params' do
    it 'extracts flat keys from params definition' do
      params = Zodra::Definition.new(name: :test_params, kind: :object)
      params.add_attribute(:name, type: :string)
      params.add_attribute(:email, type: :string)

      definition = described_class.new
      definition.add_keys_from_params(params)

      expect(definition.keys).to eq(name: nil, email: nil)
    end

    it 'excludes specified keys' do
      params = Zodra::Definition.new(name: :test_params, kind: :object)
      params.add_attribute(:name, type: :string)
      params.add_attribute(:email, type: :string)
      params.add_attribute(:date, type: :string)

      definition = described_class.new
      definition.add_keys_from_params(params, except: [:date])

      expect(definition.keys).to eq(name: nil, email: nil)
    end
  end
end
