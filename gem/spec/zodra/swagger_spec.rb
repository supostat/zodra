# frozen_string_literal: true

require_relative '../../lib/zodra/swagger'

RSpec.describe Zodra::Swagger do
  before do
    allow(Zodra).to receive(:load_definitions!)
  end

  after do
    Zodra::ContractRegistry.global.clear!
    Zodra::TypeRegistry.global.clear!
    Zodra::ApiRegistry.global.clear!
  end

  describe '.call' do
    before do
      allow(Zodra::Export).to receive(:generate_openapi).and_return({ 'api' => { openapi: '3.1.0' } })
    end

    it 'routes root to index' do
      env = { 'SCRIPT_NAME' => '/docs', 'PATH_INFO' => '/' }

      status, headers, = described_class.call(env)

      expect(status).to eq(200)
      expect(headers['content-type']).to eq('text/html; charset=utf-8')
    end

    it 'routes /specs/:slug to spec' do
      env = { 'SCRIPT_NAME' => '/docs', 'PATH_INFO' => '/specs/api' }

      status, headers, = described_class.call(env)

      expect(status).to eq(200)
      expect(headers['content-type']).to eq('application/json')
    end
  end

  describe '.serve_index' do
    let(:env) { { 'SCRIPT_NAME' => '/docs' } }

    it 'returns 200 with HTML content type' do
      status, headers, = described_class.serve_index(env)

      expect(status).to eq(200)
      expect(headers['content-type']).to eq('text/html; charset=utf-8')
    end

    it 'includes Swagger UI CDN assets' do
      _, _, body = described_class.serve_index(env)
      html = body.first

      expect(html).to include("swagger-ui-dist@#{described_class::SWAGGER_UI_VERSION}")
      expect(html).to include('swagger-ui-bundle.js')
      expect(html).to include('swagger-ui-standalone-preset.js')
      expect(html).to include('swagger-ui.css')
    end

    it 'uses configured title' do
      Zodra.configuration.openapi_title = 'My API'

      _, _, body = described_class.serve_index(env)

      expect(body.first).to include('My API — Swagger UI')
    ensure
      Zodra.configuration.openapi_title = nil
    end

    it 'escapes HTML in title' do
      Zodra.configuration.openapi_title = '<script>alert(1)</script>'

      _, _, body = described_class.serve_index(env)

      expect(body.first).not_to include('<script>alert(1)</script>')
      expect(body.first).to include('&lt;script&gt;alert(1)&lt;/script&gt;')
    ensure
      Zodra.configuration.openapi_title = nil
    end

    it 'defaults title to API' do
      _, _, body = described_class.serve_index(env)

      expect(body.first).to include('API — Swagger UI')
    end

    it 'points to spec endpoint with default slug' do
      _, _, body = described_class.serve_index(env)

      expect(body.first).to include("url: '/docs/specs/api'")
    end

    it 'uses mount path in spec URLs' do
      env['SCRIPT_NAME'] = '/swagger'

      _, _, body = described_class.serve_index(env)

      expect(body.first).to include("url: '/swagger/specs/api'")
    end

    context 'with multiple APIs' do
      before do
        Zodra::ApiRegistry.global.register('/api/v1')
        Zodra::ApiRegistry.global.register('/api/v2')
      end

      it 'generates urls array for Swagger UI' do
        _, _, body = described_class.serve_index(env)
        html = body.first

        expect(html).to include('urls: [')
        expect(html).to include("name: 'api-v1'")
        expect(html).to include("name: 'api-v2'")
        expect(html).to include("\"urls.primaryName\": 'api-v1'")
      end
    end
  end

  describe '.serve_spec' do
    let(:openapi_doc) { { openapi: '3.1.0', info: { title: 'Test', version: '1.0.0' }, paths: {}, components: { schemas: {} } } }

    before do
      allow(Zodra::Export).to receive(:generate_openapi).and_return({ 'api' => openapi_doc })
    end

    it 'returns OpenAPI JSON for valid slug' do
      env = { 'SCRIPT_NAME' => '/docs' }

      status, headers, body = described_class.serve_spec(env, 'api')

      expect(status).to eq(200)
      expect(headers['content-type']).to eq('application/json')
      expect(JSON.parse(body.first)['openapi']).to eq('3.1.0')
    end

    it 'returns 404 for unknown slug' do
      env = { 'SCRIPT_NAME' => '/docs' }

      status, _, body = described_class.serve_spec(env, 'unknown')

      expect(status).to eq(404)
      expect(JSON.parse(body.first)).to include('error' => 'not found')
    end
  end
end
