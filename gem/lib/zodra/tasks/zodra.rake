# frozen_string_literal: true

namespace :zodra do
  desc "Export all type definitions (TypeScript + Zod + contracts)"
  task export: :environment do
    Zodra.load_definitions!
    writer = Zodra::Export::Writer.new(Zodra.configuration)
    paths = writer.write_all
    paths.each { |path| puts "Generated #{path}" }
  end

  namespace :export do
    desc "Export Zod schemas"
    task zod: :environment do
      Zodra.load_definitions!
      writer = Zodra::Export::Writer.new(Zodra.configuration)
      path = writer.write(:zod)
      puts "Generated #{path}"
    end

    desc "Export TypeScript types"
    task typescript: :environment do
      Zodra.load_definitions!
      writer = Zodra::Export::Writer.new(Zodra.configuration)
      path = writer.write(:typescript)
      puts "Generated #{path}"
    end

    desc "Export client contracts barrel"
    task contracts: :environment do
      Zodra.load_definitions!
      writer = Zodra::Export::Writer.new(Zodra.configuration)
      path = writer.write_contracts
      if path
        puts "Generated #{path}"
      else
        puts "No contracts to export"
      end
    end
  end
end
