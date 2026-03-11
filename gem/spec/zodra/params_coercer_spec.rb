# frozen_string_literal: true

RSpec.describe Zodra::ParamsCoercer do
  describe '.call' do
    it 'coerces string (noop)' do
      expect(described_class.call('hello', :string)).to eq('hello')
    end

    it 'coerces integer from string' do
      expect(described_class.call('42', :integer)).to eq(42)
    end

    it 'returns coercion error for invalid integer' do
      expect(described_class.call('abc', :integer)).to eq(:coercion_error)
    end

    it 'coerces decimal from string' do
      expect(described_class.call('10.5', :decimal)).to eq(BigDecimal('10.5'))
    end

    it 'returns coercion error for invalid decimal' do
      expect(described_class.call('xyz', :decimal)).to eq(:coercion_error)
    end

    it 'returns coercion error for empty string decimal' do
      expect(described_class.call('', :decimal)).to eq(:coercion_error)
    end

    it 'coerces number from string to Float' do
      expect(described_class.call('3.14', :number)).to eq(3.14)
    end

    it 'returns coercion error for invalid number' do
      expect(described_class.call('not_a_number', :number)).to eq(:coercion_error)
    end

    it 'coerces boolean true values' do
      %w[true 1 yes].each do |value|
        expect(described_class.call(value, :boolean)).to be(true), "expected #{value.inspect} to coerce to true"
      end
    end

    it 'coerces boolean false values' do
      %w[false 0 no].each do |value|
        expect(described_class.call(value, :boolean)).to be(false), "expected #{value.inspect} to coerce to false"
      end
    end

    it 'returns coercion error for invalid boolean' do
      expect(described_class.call('maybe', :boolean)).to eq(:coercion_error)
    end

    it 'passes through actual boolean values' do
      expect(described_class.call(true, :boolean)).to be(true)
      expect(described_class.call(false, :boolean)).to be(false)
    end

    it 'coerces datetime from ISO 8601 string' do
      result = described_class.call('2024-06-15T10:30:00Z', :datetime)
      expect(result).to be_a(Time)
      expect(result.year).to eq(2024)
      expect(result.month).to eq(6)
    end

    it 'returns coercion error for invalid datetime' do
      expect(described_class.call('not-a-date', :datetime)).to eq(:coercion_error)
    end

    it 'coerces date from string' do
      result = described_class.call('2024-06-15', :date)
      expect(result).to be_a(Date)
      expect(result.year).to eq(2024)
    end

    it 'returns coercion error for invalid date' do
      expect(described_class.call('32-13-2024', :date)).to eq(:coercion_error)
    end

    it 'validates uuid format' do
      uuid = '550e8400-e29b-41d4-a716-446655440000'
      expect(described_class.call(uuid, :uuid)).to eq(uuid)
    end

    it 'returns coercion error for invalid uuid' do
      expect(described_class.call('not-a-uuid', :uuid)).to eq(:coercion_error)
    end

    it 'passes through integer values' do
      expect(described_class.call(42, :integer)).to eq(42)
    end

    it 'passes through decimal values' do
      expect(described_class.call(BigDecimal('10.5'), :decimal)).to eq(BigDecimal('10.5'))
    end

    describe 'array coercion' do
      it 'coerces array elements' do
        expect(described_class.call(%w[1 2 3], :array, of: :integer)).to eq([1, 2, 3])
      end

      it 'returns coercion error if any element fails' do
        expect(described_class.call(%w[1 abc 3], :array, of: :integer)).to eq(:coercion_error)
      end

      it 'returns coercion error for non-array input' do
        expect(described_class.call('not_array', :array, of: :integer)).to eq(:coercion_error)
      end
    end
  end
end
