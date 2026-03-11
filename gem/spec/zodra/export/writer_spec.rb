# frozen_string_literal: true

require "tmpdir"

RSpec.describe Zodra::Export::Writer do
  subject(:writer) { described_class.new(configuration) }

  let(:configuration) { Zodra::Configuration.new }
  let(:output_dir) { Dir.mktmpdir }

  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
    configuration.output_path = output_dir

    Zodra.type :user do
      string :name
      integer :age
    end
  end

  after do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
    FileUtils.rm_rf(output_dir)
  end

  describe "#write" do
    it "writes Zod schemas to schemas.ts" do
      path = writer.write(:zod)

      expect(path).to eq(File.join(output_dir, "schemas.ts"))
      content = File.read(path)
      expect(content).to include("import { z } from 'zod';")
      expect(content).to include("export const UserSchema = z.object({")
    end

    it "writes TypeScript types to types.ts" do
      path = writer.write(:typescript)

      expect(path).to eq(File.join(output_dir, "types.ts"))
      content = File.read(path)
      expect(content).to include("export interface User {")
    end

    it "uses configuration settings" do
      configuration.zod_import = "zod/v4"
      configuration.key_format = :keep

      writer.write(:zod)

      content = File.read(File.join(output_dir, "schemas.ts"))
      expect(content).to include("import { z } from 'zod/v4';")
    end

    it "creates output directory if missing" do
      nested_dir = File.join(output_dir, "deep", "nested")
      configuration.output_path = nested_dir

      writer.write(:zod)

      expect(File.exist?(File.join(nested_dir, "schemas.ts"))).to be true
    end
  end

  describe "#write_all" do
    it "writes both formats" do
      paths = writer.write_all

      expect(paths).to contain_exactly(
        File.join(output_dir, "schemas.ts"),
        File.join(output_dir, "types.ts")
      )
      expect(File.exist?(File.join(output_dir, "schemas.ts"))).to be true
      expect(File.exist?(File.join(output_dir, "types.ts"))).to be true
    end
  end
end
