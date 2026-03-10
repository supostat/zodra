# frozen_string_literal: true

RSpec.describe "Zodra DSL" do
  before { Zodra::TypeRegistry.global.clear! }

  describe ".type" do
    it "registers an object type with attributes" do
      Zodra.type :invoice do
        string :number
        decimal :amount, min: 0
        boolean :paid, default: false
      end

      definition = Zodra::TypeRegistry.global.find!(:invoice)
      expect(definition.kind).to eq(:object)
      expect(definition.attributes.keys).to eq(%i[number amount paid])
    end

    it "registers primitive types correctly" do
      Zodra.type :full_example do
        uuid :id
        string :name
        integer :count
        decimal :price
        boolean :active
        datetime :created_at
        date :birth_date
      end

      definition = Zodra::TypeRegistry.global.find!(:full_example)
      attrs = definition.attributes

      expect(attrs[:id].type).to eq(:uuid)
      expect(attrs[:name].type).to eq(:string)
      expect(attrs[:count].type).to eq(:integer)
      expect(attrs[:price].type).to eq(:decimal)
      expect(attrs[:active].type).to eq(:boolean)
      expect(attrs[:created_at].type).to eq(:datetime)
      expect(attrs[:birth_date].type).to eq(:date)
    end

    it "supports optional fields with ? suffix methods" do
      Zodra.type :profile do
        string :name
        string? :nickname
      end

      definition = Zodra::TypeRegistry.global.find!(:profile)
      expect(definition.attributes[:name].optional?).to be false
      expect(definition.attributes[:nickname].optional?).to be true
    end

    it "supports nullable fields" do
      Zodra.type :profile do
        string :bio, nullable: true
      end

      definition = Zodra::TypeRegistry.global.find!(:profile)
      expect(definition.attributes[:bio].nullable?).to be true
    end

    it "supports reference to another type" do
      Zodra.type :invoice do
        reference :customer
      end

      attr = Zodra::TypeRegistry.global.find!(:invoice).attributes[:customer]
      expect(attr.reference?).to be true
      expect(attr.reference_name).to eq(:customer)
    end

    it "supports array of references" do
      Zodra.type :invoice do
        array :items, of: :item
      end

      attr = Zodra::TypeRegistry.global.find!(:invoice).attributes[:items]
      expect(attr.array?).to be true
      expect(attr.of).to eq(:item)
    end

    it "supports timestamps shortcut" do
      Zodra.type :invoice do
        timestamps
      end

      definition = Zodra::TypeRegistry.global.find!(:invoice)
      expect(definition.attributes.keys).to eq(%i[created_at updated_at])
      expect(definition.attributes[:created_at].type).to eq(:datetime)
    end
  end

  describe ".configure" do
    after { Zodra.instance_variable_set(:@configuration, nil) }

    it "yields configuration block" do
      Zodra.configure do |c|
        c.output_path = "frontend/types"
        c.zod_import = "zod/v4"
      end

      expect(Zodra.configuration.output_path).to eq("frontend/types")
      expect(Zodra.configuration.zod_import).to eq("zod/v4")
    end
  end

  describe ".enum" do
    it "registers an enum type" do
      Zodra.enum :status, values: %i[draft sent paid]

      definition = Zodra::TypeRegistry.global.find!(:status)
      expect(definition.kind).to eq(:enum)
      expect(definition.values).to eq(%i[draft sent paid])
    end
  end

  describe ".union" do
    it "registers a discriminated union" do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank_transfer do
          string :account_number
        end
      end

      definition = Zodra::TypeRegistry.global.find!(:payment_method)
      expect(definition.kind).to eq(:union)
      expect(definition.discriminator).to eq(:type)
      expect(definition.variants.size).to eq(2)

      card = definition.variants.first
      expect(card.tag).to eq(:card)
      expect(card.attributes.keys).to eq(%i[last_four])
    end
  end
end
