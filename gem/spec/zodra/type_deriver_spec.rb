# frozen_string_literal: true

RSpec.describe Zodra::TypeDeriver do
  before do
    Zodra::TypeRegistry.global.clear!

    Zodra.type :product do
      uuid :id
      string :name, min: 1
      decimal :price, min: 0
      boolean :published
    end
  end

  after { Zodra::TypeRegistry.global.clear! }

  let(:source) { Zodra::TypeRegistry.global.find!(:product) }

  describe "pick" do
    it "copies only selected attributes" do
      derived = Zodra.type :create_product_params, from: :product, pick: [:name, :price]

      expect(derived.attributes.keys).to contain_exactly(:name, :price)
      expect(derived.attributes[:name].type).to eq(:string)
      expect(derived.attributes[:name].min).to eq(1)
    end

    it "raises on unknown attribute" do
      expect {
        Zodra.type :bad, from: :product, pick: [:nonexistent]
      }.to raise_error(ArgumentError, /nonexistent/)
    end
  end

  describe "omit" do
    it "removes specified attributes" do
      derived = Zodra.type :product_summary, from: :product, omit: [:id, :published]

      expect(derived.attributes.keys).to contain_exactly(:name, :price)
    end

    it "raises on unknown attribute" do
      expect {
        Zodra.type :bad, from: :product, omit: [:nonexistent]
      }.to raise_error(ArgumentError, /nonexistent/)
    end
  end

  describe "partial" do
    it "makes all attributes optional" do
      derived = Zodra.type :update_product_params, from: :product, partial: true

      derived.attributes.each_value do |attr|
        expect(attr).to be_optional, "expected :#{attr.name} to be optional"
      end
    end

    it "preserves constraints on partial attributes" do
      derived = Zodra.type :update_product_params, from: :product, partial: true

      expect(derived.attributes[:name].min).to eq(1)
      expect(derived.attributes[:price].min).to eq(0)
    end
  end

  describe "from without modifiers" do
    it "copies all attributes" do
      derived = Zodra.type :product_copy, from: :product

      expect(derived.attributes.keys).to contain_exactly(:id, :name, :price, :published)
    end
  end

  describe "combined pick + partial" do
    it "picks attributes and makes them optional" do
      derived = Zodra.type :patch_product, from: :product, pick: [:name, :price], partial: true

      expect(derived.attributes.keys).to contain_exactly(:name, :price)
      expect(derived.attributes[:name]).to be_optional
      expect(derived.attributes[:price]).to be_optional
    end
  end

  describe "combined omit + partial" do
    it "omits attributes and makes remaining optional" do
      derived = Zodra.type :patch_product, from: :product, omit: [:id], partial: true

      expect(derived.attributes.keys).to contain_exactly(:name, :price, :published)
      derived.attributes.each_value do |attr|
        expect(attr).to be_optional
      end
    end
  end

  describe "pick + omit mutual exclusion" do
    it "raises when both pick and omit provided" do
      expect {
        Zodra.type :bad, from: :product, pick: [:name], omit: [:id]
      }.to raise_error(ArgumentError, /Cannot use both/)
    end
  end

  describe "from with block (extend)" do
    it "copies attributes and adds new ones" do
      derived = Zodra.type :admin_product, from: :product do
        boolean :featured
        datetime :approved_at
      end

      expect(derived.attributes.keys).to contain_exactly(:id, :name, :price, :published, :featured, :approved_at)
      expect(derived.attributes[:featured].type).to eq(:boolean)
    end

    it "combines pick + block" do
      derived = Zodra.type :product_with_stock, from: :product, pick: [:name, :price] do
        integer :stock, min: 0
      end

      expect(derived.attributes.keys).to contain_exactly(:name, :price, :stock)
    end
  end

  describe "non-object source" do
    it "raises for enum source" do
      Zodra.enum :status, values: %i[draft sent]

      expect {
        Zodra.type :bad, from: :status
      }.to raise_error(ArgumentError, /object type/)
    end
  end
end

RSpec.describe "type composition in contracts" do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!

    Zodra.type :invoice do
      uuid :id
      string :number, min: 1
      decimal :amount, min: 0
      datetime :created_at
    end
  end

  after do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  describe "ActionBuilder#params from:" do
    it "derives params from a type with pick" do
      contract = Zodra.contract :invoices do
        action :create do
          params from: :invoice, pick: [:number, :amount]
        end
      end

      action = contract.find_action(:create)
      expect(action.params.attributes.keys).to contain_exactly(:number, :amount)
    end

    it "derives params from a type with omit" do
      contract = Zodra.contract :invoices do
        action :create do
          params from: :invoice, omit: [:id, :created_at]
        end
      end

      action = contract.find_action(:create)
      expect(action.params.attributes.keys).to contain_exactly(:number, :amount)
    end

    it "derives params and extends with block" do
      contract = Zodra.contract :invoices do
        action :create do
          params from: :invoice, pick: [:number, :amount] do
            string :notes
          end
        end
      end

      action = contract.find_action(:create)
      expect(action.params.attributes.keys).to contain_exactly(:number, :amount, :notes)
    end

    it "derives partial params for update" do
      contract = Zodra.contract :invoices do
        action :update do
          params from: :invoice, omit: [:id, :created_at], partial: true
        end
      end

      action = contract.find_action(:update)
      action.params.attributes.each_value do |attr|
        expect(attr).to be_optional
      end
    end
  end

  describe "ContractBuilder#type from:" do
    it "creates contract-scoped derived type" do
      contract = Zodra.contract :invoices do
        type :invoice_summary, from: :invoice, pick: [:number, :amount]
      end

      summary = contract.types.find!(:invoice_summary)
      expect(summary.attributes.keys).to contain_exactly(:number, :amount)
    end
  end

  describe "ActionBuilder#params from contract-scoped type" do
    it "resolves contract-scoped type for params derivation" do
      contract = Zodra.contract :invoices do
        type :invoice_input do
          string :number, min: 1
          decimal :amount, min: 0
        end

        action :create do
          params from: :invoice_input
        end
      end

      action = contract.find_action(:create)
      expect(action.params.attributes.keys).to contain_exactly(:number, :amount)
    end
  end

  describe "TypeBuilder#from inside block" do
    it "derives inside a block with additional attributes" do
      derived = Zodra.type :extended_invoice do
        from :invoice, omit: [:id]
        string :reference_number
      end

      expect(derived.attributes.keys).to contain_exactly(:number, :amount, :created_at, :reference_number)
    end
  end
end
