# frozen_string_literal: true

RSpec.describe Zodra::Export::OpenApiMapper do
  let(:config) do
    Zodra::Configuration.new.tap do |c|
      c.openapi_title = 'Test API'
      c.openapi_version = '1.0.0'
    end
  end

  def build_mapper(definitions: [], contracts: [], base_path: nil)
    described_class.new(definitions:, contracts:, base_path:, config:)
  end

  describe '#generate' do
    it 'produces valid OpenAPI 3.1 structure' do
      result = build_mapper.generate

      expect(result[:openapi]).to eq('3.1.0')
      expect(result[:info][:title]).to eq('Test API')
      expect(result[:info][:version]).to eq('1.0.0')
      expect(result[:paths]).to eq({})
      expect(result[:components][:schemas]).to eq({})
    end

    it 'includes description in info when configured' do
      config.openapi_description = 'A test API'

      result = build_mapper.generate

      expect(result[:info][:description]).to eq('A test API')
    end

    it 'omits description from info when not configured' do
      result = build_mapper.generate

      expect(result[:info]).not_to have_key(:description)
    end

    it 'includes servers when base_path is provided' do
      result = build_mapper(base_path: '/api/v1').generate

      expect(result[:servers]).to eq([{ url: '/api/v1' }])
    end

    it 'omits servers when no base_path' do
      result = build_mapper.generate

      expect(result).not_to have_key(:servers)
    end
  end

  describe 'schema generation' do
    it 'maps object type to JSON Schema' do
      definition = build_object(:product,
                                name: { type: :string },
                                price: { type: :decimal, min: 0 },
                                active: { type: :boolean })

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'Product')

      expect(schema[:type]).to eq('object')
      expect(schema[:properties]['name']).to eq({ type: 'string' })
      expect(schema[:properties]['price']).to include(type: 'number', minimum: 0)
      expect(schema[:properties]['active']).to eq({ type: 'boolean' })
      expect(schema[:required]).to contain_exactly('name', 'price', 'active')
    end

    it 'maps enum type to JSON Schema' do
      definition = Zodra::Definition.new(name: :status, kind: :enum, values: %i[draft sent paid])

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'Status')

      expect(schema).to eq({ type: 'string', enum: %w[draft sent paid] })
    end

    it 'maps union type with discriminator' do
      definition = Zodra::Definition.new(name: :notification, kind: :union, discriminator: :channel)
      email_attrs = { to: Zodra::Attribute.new(name: :to, type: :string) }
      sms_attrs = { phone: Zodra::Attribute.new(name: :phone, type: :string) }
      definition.add_variant(:email, attributes: email_attrs)
      definition.add_variant(:sms, attributes: sms_attrs)

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'Notification')

      expect(schema[:discriminator]).to eq({ propertyName: 'channel' })
      expect(schema[:oneOf].size).to eq(2)
      expect(schema[:oneOf][0][:properties]['channel']).to eq({ type: 'string', enum: ['email'] })
      expect(schema[:oneOf][0][:properties]['to']).to eq({ type: 'string' })
    end

    it 'handles optional attributes' do
      definition = build_object(:user,
                                name: { type: :string },
                                bio: { type: :string, optional: true })

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'User')

      expect(schema[:required]).to eq(%w[name])
    end

    it 'handles nullable attributes with OpenAPI 3.1 syntax' do
      definition = build_object(:user,
                                email: { type: :string, nullable: true })

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'User')

      expect(schema[:properties]['email'][:type]).to eq(%w[string null])
    end

    it 'handles nullable references with oneOf' do
      definition = build_object(:order,
                                customer: { type: :reference, reference_name: :customer, nullable: true })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Order', :properties, 'customer')

      expect(prop[:oneOf]).to eq([{ :$ref => '#/components/schemas/Customer' }, { type: 'null' }])
    end

    it 'maps array types' do
      definition = build_object(:order,
                                items: { type: :array, of: :order_item })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Order', :properties, 'items')

      expect(prop).to eq({ type: 'array', items: { :$ref => '#/components/schemas/OrderItem' } })
    end

    it 'maps reference types to $ref' do
      definition = build_object(:order,
                                customer: { type: :reference, reference_name: :customer })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Order', :properties, 'customer')

      expect(prop).to eq({ :$ref => '#/components/schemas/Customer' })
    end

    it 'maps inline enum attributes' do
      definition = build_object(:product,
                                status: { type: :string, enum: %w[active archived] })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Product', :properties, 'status')

      expect(prop).to eq({ type: 'string', enum: %w[active archived] })
    end

    it 'includes description and deprecated on schema' do
      definition = build_object(:product,
                                name: { type: :string, description: 'Display name' },
                                legacy_sku: { type: :string, deprecated: true })
      definition.description = 'A product'

      result = build_mapper(definitions: [definition]).generate
      schema = result.dig(:components, :schemas, 'Product')

      expect(schema[:description]).to eq('A product')
      expect(schema[:properties]['name'][:description]).to eq('Display name')
      expect(schema[:properties]['legacySku'][:deprecated]).to be true
    end

    it 'applies string constraints as minLength/maxLength' do
      definition = build_object(:user,
                                name: { type: :string, min: 1, max: 255 })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'User', :properties, 'name')

      expect(prop).to include(minLength: 1, maxLength: 255)
    end

    it 'applies numeric constraints as minimum/maximum' do
      definition = build_object(:product,
                                price: { type: :decimal, min: 0, max: 99_999 })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Product', :properties, 'price')

      expect(prop).to include(minimum: 0, maximum: 99_999)
    end

    it 'includes default values' do
      definition = build_object(:settings,
                                notifications: { type: :boolean, default: true })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Settings', :properties, 'notifications')

      expect(prop[:default]).to be true
    end

    it 'maps datetime and date types with format' do
      definition = build_object(:event,
                                starts_at: { type: :datetime },
                                event_date: { type: :date })

      result = build_mapper(definitions: [definition]).generate
      props = result.dig(:components, :schemas, 'Event', :properties)

      expect(props['startsAt']).to eq({ type: 'string', format: 'date-time' })
      expect(props['eventDate']).to eq({ type: 'string', format: 'date' })
    end

    it 'maps uuid type with format' do
      definition = build_object(:entity,
                                id: { type: :uuid })

      result = build_mapper(definitions: [definition]).generate
      prop = result.dig(:components, :schemas, 'Entity', :properties, 'id')

      expect(prop).to eq({ type: 'string', format: 'uuid' })
    end
  end

  describe 'path generation' do
    it 'generates paths from contract actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:index)
        action.http_method = :get
        action.path = '/api/v1/products'
        action.response_type = :product
      end

      result = build_mapper(contracts: [contract]).generate

      expect(result[:paths]).to have_key('/api/v1/products')
      expect(result[:paths]['/api/v1/products']).to have_key('get')
    end

    it 'converts Rails path params to OpenAPI format' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/api/v1/products/:id'
        action.response_type = :product
      end

      result = build_mapper(contracts: [contract]).generate

      expect(result[:paths]).to have_key('/api/v1/products/{id}')
    end

    it 'sets operationId from action and contract names' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/products'
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products', 'post')

      expect(operation[:operationId]).to eq('create_products')
    end

    it 'includes summary from action description' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:index)
        action.http_method = :get
        action.path = '/products'
        action.description = 'List all products'
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products', 'get')

      expect(operation[:summary]).to eq('List all products')
    end

    it 'marks deprecated actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:search)
        action.http_method = :get
        action.path = '/products/search'
        action.deprecated_message = 'Use index with filters'
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products/search', 'get')

      expect(operation[:deprecated]).to be true
    end
  end

  describe 'request parameters' do
    it 'generates path parameters' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/products/:id'
        action.response_type = :product
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products/{id}', 'get')
      path_param = operation[:parameters].find { |p| p[:name] == 'id' }

      expect(path_param[:in]).to eq('path')
      expect(path_param[:required]).to be true
    end

    it 'generates query parameters for GET actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:index)
        action.http_method = :get
        action.path = '/products'
        Zodra::TypeBuilder.new(action.params).instance_eval do
          string? :search
          integer? :page
        end
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products', 'get')
      params = operation[:parameters]

      search_param = params.find { |p| p[:name] == 'search' }
      expect(search_param[:in]).to eq('query')
      expect(search_param).not_to have_key(:required)
    end

    it 'generates request body for POST actions' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/products'
        Zodra::TypeBuilder.new(action.params).instance_eval do
          string :name
          decimal :price
        end
      end

      result = build_mapper(contracts: [contract]).generate
      operation = result.dig(:paths, '/products', 'post')
      body = operation[:requestBody]

      expect(body[:required]).to be true
      schema = body.dig(:content, 'application/json', :schema)
      expect(schema[:properties]).to have_key('name')
      expect(schema[:properties]).to have_key('price')
      expect(schema[:required]).to contain_exactly('name', 'price')
    end
  end

  describe 'response generation' do
    it 'wraps response in data envelope' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:show)
        action.http_method = :get
        action.path = '/products/:id'
        action.response_type = :product
      end

      result = build_mapper(contracts: [contract]).generate
      response_schema = result.dig(:paths, '/products/{id}', 'get', :responses, '200', :content, 'application/json', :schema)

      expect(response_schema[:properties][:data]).to eq({ :$ref => '#/components/schemas/Product' })
      expect(response_schema[:required]).to eq(%w[data])
    end

    it 'wraps collection responses in data array with meta' do
      contract = build_contract(:products) do |c|
        action = c.add_action(:index)
        action.http_method = :get
        action.path = '/products'
        action.response_type = :product
        action.collection!
      end

      result = build_mapper(contracts: [contract]).generate
      response_schema = result.dig(:paths, '/products', 'get', :responses, '200', :content, 'application/json', :schema)

      expect(response_schema[:properties][:data]).to eq({
                                                          type: 'array',
                                                          items: { :$ref => '#/components/schemas/Product' }
                                                        })
      expect(response_schema[:properties][:meta]).to eq({ type: 'object' })
    end

    it 'generates error responses' do
      contract = build_contract(:invoices) do |c|
        action = c.add_action(:create)
        action.http_method = :post
        action.path = '/invoices'
        action.add_error(:already_finalized, status: 409)
      end

      result = build_mapper(contracts: [contract]).generate
      error_response = result.dig(:paths, '/invoices', 'post', :responses, '409')

      expect(error_response[:description]).to eq('Error: already_finalized')
      error_schema = error_response.dig(:content, 'application/json', :schema)
      expect(error_schema[:properties][:error][:properties][:code][:enum]).to eq(['already_finalized'])
    end
  end

  describe '#to_json' do
    it 'returns valid JSON string' do
      mapper = build_mapper
      json = mapper.to_json

      parsed = JSON.parse(json)
      expect(parsed['openapi']).to eq('3.1.0')
    end
  end

  private

  def build_object(name, **attrs)
    definition = Zodra::Definition.new(name:, kind: :object)
    attrs.each do |attr_name, options|
      definition.add_attribute(attr_name, **options)
    end
    definition
  end

  def build_contract(name)
    contract = Zodra::Contract.new(name:)
    yield contract if block_given?
    contract
  end
end
