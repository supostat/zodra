# frozen_string_literal: true

namespace :zodra do
  desc "Export all type definitions (TypeScript + Zod)"
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
  end
end
