# frozen_string_literal: true

RSpec.describe Zodra::ErrorTransformer do
  describe '.transform_keys' do
    it 'transforms top-level keys to camelCase' do
      errors = { first_name: ['required'], last_name: ['required'] }
      result = described_class.transform_keys(errors, key_format: :camel)

      expect(result).to eq('firstName' => ['required'], 'lastName' => ['required'])
    end

    it 'returns errors unchanged when key_format is :keep' do
      errors = { first_name: ['required'] }
      result = described_class.transform_keys(errors, key_format: :keep)

      expect(result).to eq(first_name: ['required'])
    end

    it 'transforms keys inside arrays of hashes' do
      errors = {
        hours_acceptance_breaks: [
          { starts_at: ['is required'], ends_at: ['is required'] }
        ]
      }

      result = described_class.transform_keys(errors, key_format: :camel)

      expect(result).to eq(
        'hoursAcceptanceBreaks' => [
          { 'startsAt' => ['is required'], 'endsAt' => ['is required'] }
        ]
      )
    end

    it 'preserves string arrays (error messages) untouched' do
      errors = { name: ['is required', 'is too short'] }
      result = described_class.transform_keys(errors, key_format: :camel)

      expect(result).to eq('name' => ['is required', 'is too short'])
    end

    it 'handles mixed arrays with hashes and nils' do
      errors = {
        items: [nil, { text: ['required'] }, nil]
      }

      result = described_class.transform_keys(errors, key_format: :camel)

      expect(result).to eq(
        'items' => [nil, { 'text' => ['required'] }, nil]
      )
    end

    it 'handles deeply nested structures' do
      errors = {
        sections: [
          { line_items: [{ unit_price: ['is invalid'] }] }
        ]
      }

      result = described_class.transform_keys(errors, key_format: :camel)

      expect(result).to eq(
        'sections' => [
          { 'lineItems' => [{ 'unitPrice' => ['is invalid'] }] }
        ]
      )
    end
  end

  describe '.validate_keys!' do
    before do
      stub_const('Rails', double('Rails', env: double('env', production?: false)))
    end

    context 'with flat valid_keys array (legacy)' do
      it 'raises on unknown keys' do
        expect do
          described_class.validate_keys!(
            { typo: ['err'] },
            valid_keys: %i[name email base],
            action_name: :create
          )
        end.to raise_error(Zodra::Error, /Unknown error keys \[:typo\]/)
      end

      it 'passes with valid keys' do
        expect do
          described_class.validate_keys!(
            { name: ['err'] },
            valid_keys: %i[name email base],
            action_name: :create
          )
        end.not_to raise_error
      end

      it 'skips validation when valid_keys is nil' do
        expect do
          described_class.validate_keys!(
            { anything: ['err'] },
            valid_keys: nil,
            action_name: :create
          )
        end.not_to raise_error
      end
    end

    context 'with ErrorKeysDefinition' do
      let(:definition) do
        defn = Zodra::ErrorKeysDefinition.new
        defn.add_key(:base)
        defn.add_key(:name)
        defn.add_key(:items, children: { starts_at: nil, ends_at: nil })
        defn
      end

      it 'raises on unknown top-level keys' do
        expect do
          described_class.validate_keys!(
            { typo: ['err'] },
            valid_keys: definition,
            action_name: :create
          )
        end.to raise_error(Zodra::Error, /Unknown error keys \[:typo\].*for action :create/)
      end

      it 'passes with valid top-level keys' do
        expect do
          described_class.validate_keys!(
            { name: ['err'], base: ['err'] },
            valid_keys: definition,
            action_name: :create
          )
        end.not_to raise_error
      end

      it 'raises on unknown nested keys' do
        expect do
          described_class.validate_keys!(
            { items: [{ starts_at: ['err'], unknown_field: ['err'] }] },
            valid_keys: definition,
            action_name: :create
          )
        end.to raise_error(Zodra::Error, /Unknown error keys \[:unknown_field\] in items\[0\]/)
      end

      it 'validates multiple elements in array' do
        expect do
          described_class.validate_keys!(
            { items: [{ starts_at: ['err'] }, { bad_key: ['err'] }] },
            valid_keys: definition,
            action_name: :create
          )
        end.to raise_error(Zodra::Error, /items\[1\]/)
      end

      it 'passes with valid nested keys' do
        expect do
          described_class.validate_keys!(
            { name: ['err'], items: [{ starts_at: ['err'], ends_at: ['err'] }] },
            valid_keys: definition,
            action_name: :create
          )
        end.not_to raise_error
      end

      it 'skips nested validation for non-array values' do
        expect do
          described_class.validate_keys!(
            { items: ['is required'] },
            valid_keys: definition,
            action_name: :create
          )
        end.not_to raise_error
      end

      it 'skips nil elements in arrays' do
        expect do
          described_class.validate_keys!(
            { items: [nil, { starts_at: ['err'] }, nil] },
            valid_keys: definition,
            action_name: :create
          )
        end.not_to raise_error
      end
    end

    context 'in production' do
      before do
        stub_const('Rails', double('Rails', env: double('env', production?: true)))
      end

      it 'logs warning instead of raising' do
        logger = double('Logger')
        allow(Zodra).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn)

        described_class.validate_keys!(
          { typo: ['err'] },
          valid_keys: %i[name base],
          action_name: :create
        )

        expect(logger).to have_received(:warn).with(/Unknown error keys \[:typo\]/)
      end
    end
  end

  describe '.normalize' do
    it 'converts objects with to_hash' do
      obj = double('errors', to_hash: { name: ['err'] })
      expect(described_class.normalize(obj)).to eq(name: ['err'])
    end

    it 'converts objects with messages' do
      obj = double('errors', messages: { name: ['err'] })
      expect(described_class.normalize(obj)).to eq(name: ['err'])
    end

    it 'returns plain hashes as-is' do
      hash = { name: ['err'] }
      expect(described_class.normalize(hash)).to eq(name: ['err'])
    end
  end
end
