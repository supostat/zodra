# frozen_string_literal: true

RSpec.describe "Custom scalar types" do
  before do
    Zodra::ScalarRegistry.global.clear!
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  after do
    Zodra::ScalarRegistry.global.clear!
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  describe "DSL registration" do
    it "registers a scalar via Zodra.scalar" do
      Zodra.scalar :ui_date, base: :date do |value|
        Date.strptime(value.to_s, "%d-%m-%Y")
      rescue Date::Error
        :coercion_error
      end

      expect(Zodra::ScalarRegistry.global.exists?(:ui_date)).to be true
      scalar = Zodra::ScalarRegistry.global.find(:ui_date)
      expect(scalar.base).to eq(:date)
    end
  end

  describe "TypeBuilder integration" do
    before do
      Zodra.scalar :ui_date, base: :date do |value|
        Date.strptime(value.to_s, "%d-%m-%Y")
      rescue Date::Error
        :coercion_error
      end
    end

    it "uses custom scalar in type definition" do
      definition = Zodra.type :event do
        ui_date :start_date
      end

      attr = definition.attributes[:start_date]
      expect(attr.type).to eq(:ui_date)
      expect(attr).not_to be_optional
    end

    it "supports optional custom scalar with ? suffix" do
      definition = Zodra.type :event do
        ui_date? :end_date
      end

      attr = definition.attributes[:end_date]
      expect(attr.type).to eq(:ui_date)
      expect(attr).to be_optional
    end

    it "passes options to custom scalar" do
      definition = Zodra.type :event do
        ui_date :start_date, nullable: true
      end

      attr = definition.attributes[:start_date]
      expect(attr).to be_nullable
    end

    it "raises NoMethodError for unknown type" do
      expect do
        Zodra.type :bad do
          unknown_type :field
        end
      end.to raise_error(NoMethodError)
    end
  end

  describe "params coercion" do
    before do
      Zodra.scalar :ui_date, base: :date do |value|
        Date.strptime(value.to_s, "%d-%m-%Y")
      rescue Date::Error
        :coercion_error
      end
    end

    it "coerces valid value through custom scalar" do
      contract = Zodra.contract :events do
        action :create do
          params do
            ui_date :start_date
          end
        end
      end

      schema = contract.find_action(:create).params
      result = Zodra::ParamsParser.call({ "start_date" => "23-12-2026" }, schema:)

      expect(result).to be_valid
      expect(result.params[:start_date]).to eq(Date.new(2026, 12, 23))
    end

    it "returns coercion error for invalid value" do
      contract = Zodra.contract :events do
        action :create do
          params do
            ui_date :start_date
          end
        end
      end

      schema = contract.find_action(:create).params
      result = Zodra::ParamsParser.call({ "start_date" => "not-a-date" }, schema:)

      expect(result).to be_invalid
      expect(result.errors[:start_date]).to include("is not a valid ui_date")
    end

    it "handles optional custom scalar" do
      contract = Zodra.contract :events do
        action :create do
          params do
            ui_date? :end_date
          end
        end
      end

      schema = contract.find_action(:create).params
      result = Zodra::ParamsParser.call({}, schema:)

      expect(result).to be_valid
      expect(result.params).not_to have_key(:end_date)
    end
  end

  describe "export" do
    before do
      Zodra.scalar :ui_date, base: :date do |value|
        Date.strptime(value.to_s, "%d-%m-%Y")
      rescue Date::Error
        :coercion_error
      end

      Zodra.type :event do
        uuid :id
        ui_date :start_date
        ui_date? :end_date
      end
    end

    it "exports TypeScript with base type mapping" do
      output = Zodra::Export.generate(:typescript, key_format: :keep)

      expect(output).to include("start_date: string;")
      expect(output).to include("end_date?: string;")
    end

    it "exports Zod with base type mapping" do
      output = Zodra::Export.generate(:zod, key_format: :keep)

      expect(output).to include("start_date: z.iso.date(),")
      expect(output).to include("end_date: z.iso.date().optional(),")
    end
  end
end
