# frozen_string_literal: true

require 'json'

module Zodra
  module Swagger
    SWAGGER_UI_VERSION = '5.21.0'
    SPECS_PREFIX = '/specs/'

    def self.call(env)
      path_info = env['PATH_INFO'] || '/'

      if path_info.start_with?(SPECS_PREFIX)
        slug = path_info.delete_prefix(SPECS_PREFIX)
        serve_spec(env, slug)
      else
        serve_index(env)
      end
    end

    def self.serve_index(env)
      ensure_definitions_loaded!
      slugs = openapi_slugs
      mount_path = env['SCRIPT_NAME']
      html = render_html(mount_path, slugs)

      [200, { 'content-type' => 'text/html; charset=utf-8' }, [html]]
    end

    def self.serve_spec(_env, slug)
      ensure_definitions_loaded!
      docs = Export.generate_openapi
      doc = docs[slug]

      return [404, { 'content-type' => 'application/json' }, ['{"error":"not found"}']] unless doc

      [200, { 'content-type' => 'application/json' }, [JSON.pretty_generate(doc)]]
    end

    def self.ensure_definitions_loaded!
      return if ContractRegistry.global.any? || TypeRegistry.global.any?

      Zodra.load_definitions!
    end

    def self.openapi_slugs
      api_definitions = ApiRegistry.global.to_a

      if api_definitions.any?
        api_definitions.map { |d| d.base_path.tr('/', '-').delete_prefix('-') }
      else
        ['api']
      end
    end

    def self.spec_config_js(mount_path, slugs)
      if slugs.size > 1
        urls = slugs.map { |s| "{ url: '#{escape_js(mount_path)}/specs/#{escape_js(s)}', name: '#{escape_js(s)}' }" }
        "urls: [#{urls.join(', ')}], \"urls.primaryName\": '#{escape_js(slugs.first)}'"
      else
        "url: '#{escape_js(mount_path)}/specs/#{escape_js(slugs.first)}'"
      end
    end

    def self.render_html(mount_path, slugs)
      cdn = "https://unpkg.com/swagger-ui-dist@#{SWAGGER_UI_VERSION}"
      title = escape_html(Zodra.configuration.openapi_title || 'API')
      spec_config = spec_config_js(mount_path, slugs)

      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>#{title} — Swagger UI</title>
          <link rel="stylesheet" href="#{cdn}/swagger-ui.css">
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="#{cdn}/swagger-ui-bundle.js"></script>
          <script src="#{cdn}/swagger-ui-standalone-preset.js"></script>
          <script>
            SwaggerUIBundle({
              dom_id: '#swagger-ui',
              #{spec_config},
              presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
              layout: 'StandaloneLayout',
              deepLinking: true
            });
          </script>
        </body>
        </html>
      HTML
    end

    def self.escape_html(text)
      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
    end

    def self.escape_js(text)
      text.to_s.gsub('\\', '\\\\\\\\').gsub("'", "\\\\'")
    end

    private_class_method :render_html, :spec_config_js, :openapi_slugs, :ensure_definitions_loaded!, :escape_html, :escape_js
  end
end
