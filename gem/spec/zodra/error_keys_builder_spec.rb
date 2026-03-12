# frozen_string_literal: true

RSpec.describe Zodra::ErrorKeysBuilder do
  let(:definition) { Zodra::ErrorKeysDefinition.new }
  let(:params_definition) do
    params = Zodra::Definition.new(name: :test_params, kind: :object)
    params.add_attribute(:name, type: :string)
    params.add_attribute(:email, type: :string)
    params.add_attribute(:date, type: :string)
    params
  end

  def build(params: params_definition, &block)
    described_class.new(definition, params_definition: params).instance_eval(&block)
    definition
  end

  describe '#key' do
    it 'adds a flat key' do
      result = build { key :base }

      expect(result.keys).to eq(base: nil)
    end

    it 'adds a nested key with block' do
      result = build do
        key :items do
          key :starts_at
          key :ends_at
        end
      end

      expect(result.keys).to eq(items: { starts_at: nil, ends_at: nil })
    end

    it 'supports deeply nested keys' do
      result = build do
        key :sections do
          key :items do
            key :text
          end
        end
      end

      expect(result.keys).to eq(sections: { items: { text: nil } })
    end
  end

  describe '#from_params' do
    it 'adds all param keys' do
      result = build { from_params }

      expect(result.keys).to eq(name: nil, email: nil, date: nil)
    end

    it 'adds param keys except specified' do
      result = build { from_params except: [:date] }

      expect(result.keys).to eq(name: nil, email: nil)
    end

    it 'combines with explicit keys' do
      result = build do
        from_params except: [:date]
        key :base
        key :display_name
      end

      expect(result.keys).to eq(name: nil, email: nil, base: nil, display_name: nil)
    end

    it 'raises without params_definition' do
      expect do
        described_class.new(definition, params_definition: nil).instance_eval do
          from_params
        end
      end.to raise_error(Zodra::Error, /from_params requires a params definition/)
    end
  end
end
