# frozen_string_literal: true

RSpec.describe Zodra::ParamsParser do
  describe ".call" do
    it "returns valid result with coerced params" do
      schema = build_schema(
        name: { type: :string },
        age: { type: :integer }
      )

      result = described_class.call({ "name" => "John", "age" => "30" }, schema:)

      expect(result).to be_valid
      expect(result.params).to eq({ name: "John", age: 30 })
    end

    it "filters unknown keys" do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ "name" => "John", "admin" => "true" }, schema:)

      expect(result).to be_valid
      expect(result.params.keys).to eq([:name])
    end

    it "symbolizes keys" do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ "name" => "John" }, schema:)

      expect(result.params).to have_key(:name)
    end

    it "applies default values for missing optional params" do
      schema = build_schema(page: { type: :integer, optional: true, default: 1 })

      result = described_class.call({}, schema:)

      expect(result).to be_valid
      expect(result.params[:page]).to eq(1)
    end

    it "does not apply default when value is provided" do
      schema = build_schema(page: { type: :integer, optional: true, default: 1 })

      result = described_class.call({ "page" => "5" }, schema:)

      expect(result).to be_valid
      expect(result.params[:page]).to eq(5)
    end

    it "omits optional params without default when absent" do
      schema = build_schema(nickname: { type: :string, optional: true })

      result = described_class.call({}, schema:)

      expect(result).to be_valid
      expect(result.params).not_to have_key(:nickname)
    end

    it "returns invalid result with errors" do
      schema = build_schema(name: { type: :string })

      result = described_class.call({}, schema:)

      expect(result).to be_invalid
      expect(result.errors[:name]).to include("is required")
      expect(result.params).to be_empty
    end

    it "handles mixed valid and invalid params" do
      schema = build_schema(
        name: { type: :string },
        age: { type: :integer }
      )

      result = described_class.call({ "name" => "John", "age" => "abc" }, schema:)

      expect(result).to be_invalid
      expect(result.errors[:age]).to include("is not a valid integer")
    end

    it "accepts symbol keys in input" do
      schema = build_schema(name: { type: :string })

      result = described_class.call({ name: "John" }, schema:)

      expect(result).to be_valid
      expect(result.params[:name]).to eq("John")
    end

    it "handles nullable params" do
      schema = build_schema(bio: { type: :string, nullable: true })

      result = described_class.call({ "bio" => nil }, schema:)

      expect(result).to be_valid
      expect(result.params[:bio]).to be_nil
    end

    it "handles array params" do
      schema = build_schema(ids: { type: :array, of: :integer })

      result = described_class.call({ "ids" => ["1", "2", "3"] }, schema:)

      expect(result).to be_valid
      expect(result.params[:ids]).to eq([1, 2, 3])
    end
  end

  describe Zodra::ParamsParser::Result do
    it "is valid when errors are empty" do
      result = described_class.new(params: { name: "John" }, errors: {})

      expect(result).to be_valid
      expect(result).not_to be_invalid
    end

    it "is invalid when errors exist" do
      result = described_class.new(params: {}, errors: { name: ["is required"] })

      expect(result).to be_invalid
      expect(result).not_to be_valid
    end
  end

  private

  def build_schema(**attrs)
    definition = Zodra::Definition.new(name: :test, kind: :object)
    attrs.each do |attr_name, options|
      definition.add_attribute(attr_name, **options)
    end
    definition
  end
end
