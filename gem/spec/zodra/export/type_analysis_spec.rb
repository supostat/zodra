# frozen_string_literal: true

RSpec.describe Zodra::Export::TypeAnalysis do
  before do
    Zodra::TypeRegistry.global.clear!
  end

  after do
    Zodra::TypeRegistry.global.clear!
  end

  def all_definitions
    Zodra::TypeRegistry.global.to_a
  end

  describe '.call' do
    context 'topological sorting' do
      it 'sorts dependencies before dependents' do
        Zodra.type(:invoice) { reference :customer }
        Zodra.type(:customer) { string :name }

        result = described_class.call(all_definitions)

        names = result.sorted.map(&:name)
        expect(names.index(:customer)).to be < names.index(:invoice)
      end

      it 'sorts deep dependency chains' do
        Zodra.type(:invoice) { reference :customer }
        Zodra.type(:customer) { reference :address }
        Zodra.type(:address) { string :city }

        result = described_class.call(all_definitions)

        names = result.sorted.map(&:name)
        expect(names.index(:address)).to be < names.index(:customer)
        expect(names.index(:customer)).to be < names.index(:invoice)
      end

      it 'sorts array dependencies' do
        Zodra.type(:invoice) { array :items, of: :item }
        Zodra.type(:item) { string :description }

        result = described_class.call(all_definitions)

        names = result.sorted.map(&:name)
        expect(names.index(:item)).to be < names.index(:invoice)
      end

      it 'preserves independent types in original order' do
        Zodra.type(:alpha) { string :name }
        Zodra.type(:beta) { string :name }
        Zodra.type(:gamma) { string :name }

        result = described_class.call(all_definitions)

        expect(result.sorted.map(&:name)).to eq(%i[alpha beta gamma])
      end

      it 'handles enums without dependencies' do
        Zodra.enum :status, values: %i[draft sent]
        Zodra.type(:invoice) { string :number }

        result = described_class.call(all_definitions)

        expect(result.sorted.map(&:name)).to contain_exactly(:status, :invoice)
      end
    end

    context 'cycle detection' do
      it 'detects self-referencing types' do
        Zodra.type :comment do
          string :text
          array :replies, of: :comment
        end

        result = described_class.call(all_definitions)

        expect(result.cycles).to include(:comment)
      end

      it 'detects mutual reference cycles' do
        Zodra.type :employee do
          string :name
          reference :department
        end
        Zodra.type :department do
          string :title
          reference :employee
        end

        result = described_class.call(all_definitions)

        expect(result.cycles).to include(:employee, :department)
      end

      it 'returns empty cycles for acyclic graph' do
        Zodra.type(:customer) { string :name }
        Zodra.type(:invoice) { reference :customer }

        result = described_class.call(all_definitions)

        expect(result.cycles).to be_empty
      end

      it 'includes all cyclic types in sorted output' do
        Zodra.type :comment do
          string :text
          array :replies, of: :comment
        end

        result = described_class.call(all_definitions)

        expect(result.sorted.map(&:name)).to include(:comment)
      end
    end

    context 'mixed cyclic and acyclic' do
      it 'sorts acyclic dependencies and detects cycles' do
        Zodra.type(:address) { string :city }
        Zodra.type(:customer) do
          reference :address
        end
        Zodra.type :comment do
          string :text
          array :replies, of: :comment
        end

        result = described_class.call(all_definitions)

        names = result.sorted.map(&:name)
        expect(names.index(:address)).to be < names.index(:customer)
        expect(result.cycles).to eq(Set[:comment])
      end
    end
  end
end
