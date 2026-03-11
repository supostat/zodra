# frozen_string_literal: true

RSpec.describe Zodra::ApiRegistry do
  subject(:registry) { described_class.new }

  describe '#register' do
    it 'registers API definition' do
      api = registry.register('/api/v1')

      expect(api).to be_a(Zodra::ApiDefinition)
      expect(api.base_path).to eq('/api/v1')
    end

    it 'raises on duplicate registration' do
      registry.register('/api/v1')

      expect { registry.register('/api/v1') }.to raise_error(Zodra::DuplicateTypeError)
    end
  end

  describe '#find' do
    it 'finds registered API' do
      registry.register('/api/v1')

      expect(registry.find('/api/v1')).to be_a(Zodra::ApiDefinition)
    end

    it 'returns nil for unregistered API' do
      expect(registry.find('/api/v2')).to be_nil
    end
  end

  describe '#clear!' do
    it 'removes all registered APIs' do
      registry.register('/api/v1')
      registry.clear!

      expect(registry.find('/api/v1')).to be_nil
    end
  end
end
