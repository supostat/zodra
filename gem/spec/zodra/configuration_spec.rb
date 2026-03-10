# frozen_string_literal: true

RSpec.describe Zodra::Configuration do
  subject(:configuration) { described_class.new }

  it "has default output_path" do
    expect(configuration.output_path).to eq("app/javascript/types")
  end

  it "has default key_format" do
    expect(configuration.key_format).to eq(:camel)
  end

  it "has default zod_import" do
    expect(configuration.zod_import).to eq("zod")
  end

  it "allows overriding values" do
    configuration.output_path = "frontend/types"
    configuration.key_format = :keep
    configuration.zod_import = "zod/v4"

    expect(configuration.output_path).to eq("frontend/types")
    expect(configuration.key_format).to eq(:keep)
    expect(configuration.zod_import).to eq("zod/v4")
  end
end
