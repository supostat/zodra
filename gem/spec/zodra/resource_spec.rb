# frozen_string_literal: true

RSpec.describe Zodra::Resource do
  describe '#crud_actions' do
    it 'returns all CRUD actions for plural resource' do
      resource = described_class.new(name: :invoices)

      expect(resource.crud_actions).to eq(%i[index show create update destroy])
    end

    it 'excludes index for singular resource' do
      resource = described_class.new(name: :profile, singular: true)

      expect(resource.crud_actions).to eq(%i[show create update destroy])
    end

    it 'filters with only:' do
      resource = described_class.new(name: :invoices, only: %i[index show])

      expect(resource.crud_actions).to eq(%i[index show])
    end

    it 'filters with except:' do
      resource = described_class.new(name: :invoices, except: %i[destroy])

      expect(resource.crud_actions).to eq(%i[index show create update])
    end
  end

  describe '#singular?' do
    it 'returns false for plural resource' do
      expect(described_class.new(name: :invoices).singular?).to be false
    end

    it 'returns true for singular resource' do
      expect(described_class.new(name: :profile, singular: true).singular?).to be true
    end
  end

  describe '#contract_name' do
    it 'defaults to resource name' do
      resource = described_class.new(name: :invoices)

      expect(resource.contract_name).to eq(:invoices)
    end

    it 'uses explicit contract name' do
      resource = described_class.new(name: :invoices, contract: :billing_invoices)

      expect(resource.contract_name).to eq(:billing_invoices)
    end
  end

  describe 'custom actions' do
    it 'adds member actions' do
      resource = described_class.new(name: :invoices)
      resource.add_member_action(:patch, :void)

      expect(resource.custom_actions).to eq([{ name: :void, http_method: :patch, member: true }])
    end

    it 'adds collection actions' do
      resource = described_class.new(name: :invoices)
      resource.add_collection_action(:get, :search)

      expect(resource.custom_actions).to eq([{ name: :search, http_method: :get, member: false }])
    end
  end

  describe '#add_child' do
    it 'adds nested resource' do
      parent = described_class.new(name: :invoices)
      child = described_class.new(name: :items)
      parent.add_child(child)

      expect(parent.children).to eq([child])
    end
  end
end
