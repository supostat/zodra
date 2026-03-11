# frozen_string_literal: true

RSpec.describe Zodra::ScalarRegistry do
  subject(:registry) { described_class.new }

  after { registry.clear! }

  describe "#register" do
    it "registers a custom scalar type" do
      coercer = ->(value) { Date.strptime(value.to_s, "%d-%m-%Y") }
      registry.register(:ui_date, base: :date, coercer:)

      expect(registry.exists?(:ui_date)).to be true
    end

    it "raises on duplicate registration" do
      coercer = ->(value) { value }
      registry.register(:ui_date, base: :date, coercer:)

      expect { registry.register(:ui_date, base: :date, coercer:) }
        .to raise_error(Zodra::DuplicateTypeError, /ui_date/)
    end
  end

  describe "#find" do
    it "returns registered scalar" do
      coercer = ->(value) { value }
      registry.register(:ui_date, base: :date, coercer:)

      scalar = registry.find(:ui_date)
      expect(scalar.name).to eq(:ui_date)
      expect(scalar.base).to eq(:date)
    end

    it "returns nil for missing scalar" do
      expect(registry.find(:missing)).to be_nil
    end
  end

  describe "#clear!" do
    it "removes all registered scalars" do
      registry.register(:ui_date, base: :date, coercer: ->(v) { v })
      registry.clear!

      expect(registry.exists?(:ui_date)).to be false
    end
  end
end
