# frozen_string_literal: true

RSpec.describe Zodra::ApiDefinition do
  describe '#namespaces' do
    it 'parses base_path into namespace segments' do
      api = described_class.new(base_path: '/api/v1')

      expect(api.namespaces).to eq(%i[api v1])
    end
  end

  describe '#controller_namespace' do
    it 'joins namespaces with slash' do
      api = described_class.new(base_path: '/api/v1')

      expect(api.controller_namespace).to eq('api/v1')
    end
  end

  describe '#add_resource' do
    it 'stores resources' do
      api = described_class.new(base_path: '/api/v1')
      resource = Zodra::Resource.new(name: :invoices)
      api.add_resource(resource)

      expect(api.resources).to eq([resource])
    end
  end
end
