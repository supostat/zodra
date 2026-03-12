# frozen_string_literal: true

namespace :zodra do
  desc 'Export all type definitions (types + contracts)'
  task export: :environment do
    Zodra.load_definitions!
    writer = Zodra::Export::Writer.new(Zodra.configuration)
    paths = writer.write_all
    paths.each { |path| puts "Generated #{path}" }
  end

  desc 'Generate OpenAPI 3.1 JSON specs'
  task openapi: :environment do
    require 'json'

    Zodra.load_definitions!
    output_path = Zodra.configuration.output_path
    docs = Zodra::Export.generate_openapi

    docs.each do |slug, doc|
      file_path = File.join(output_path, "openapi-#{slug}.json")
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, JSON.pretty_generate(doc))
      puts "Generated #{file_path}"
    end
  end
end
