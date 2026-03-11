# frozen_string_literal: true

RSpec.describe 'Params parsing pipeline', :acceptance do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  it 'parses and validates params from contract action' do
    Zodra.contract :invoices do
      action :create do
        params do
          string :number, min: 1
          decimal :amount, min: 0
          boolean :paid
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:invoices).find_action(:create)

    result = Zodra::ParamsParser.call(
      { 'number' => 'INV-001', 'amount' => '99.5', 'paid' => 'true' },
      schema: action.params
    )

    expect(result).to be_valid
    expect(result.params[:number]).to eq('INV-001')
    expect(result.params[:amount]).to eq(BigDecimal('99.5'))
    expect(result.params[:paid]).to be(true)
  end

  it 'returns field-level errors for invalid params' do
    Zodra.contract :invoices do
      action :create do
        params do
          string :number, min: 3
          decimal :amount, min: 0
          integer :quantity
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:invoices).find_action(:create)

    result = Zodra::ParamsParser.call(
      { 'number' => 'AB', 'amount' => '-5', 'quantity' => 'abc' },
      schema: action.params
    )

    expect(result).to be_invalid
    expect(result.errors[:number]).to include(match(/too short/))
    expect(result.errors[:amount]).to include(match(/greater than or equal/))
    expect(result.errors[:quantity]).to include(match(/not a valid integer/))
  end

  it 'handles required, optional, and default values' do
    Zodra.contract :users do
      action :create do
        params do
          string :name
          string? :nickname
          integer :page, default: 1
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:users).find_action(:create)

    result = Zodra::ParamsParser.call(
      { 'name' => 'John' },
      schema: action.params
    )

    expect(result).to be_valid
    expect(result.params[:name]).to eq('John')
    expect(result.params).not_to have_key(:nickname)
    expect(result.params[:page]).to eq(1)
  end

  it 'returns error for missing required param' do
    Zodra.contract :users do
      action :create do
        params do
          string :name
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:users).find_action(:create)

    result = Zodra::ParamsParser.call({}, schema: action.params)

    expect(result).to be_invalid
    expect(result.errors[:name]).to include('is required')
  end

  it 'rejects unknown params in strict mode' do
    Zodra.contract :users do
      action :create do
        params do
          string :name
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:users).find_action(:create)

    result = Zodra::ParamsParser.call(
      { 'name' => 'John', 'admin' => 'true', 'role' => 'superuser' },
      schema: action.params
    )

    expect(result).to be_invalid
    expect(result.errors[:admin]).to include('is not allowed')
    expect(result.errors[:role]).to include('is not allowed')
  end

  it 'filters unknown params in non-strict mode' do
    Zodra.contract :users do
      action :create do
        params do
          string :name
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:users).find_action(:create)

    result = Zodra::ParamsParser.call(
      { 'name' => 'John', 'admin' => 'true' },
      schema: action.params,
      strict: false
    )

    expect(result).to be_valid
    expect(result.params.keys).to eq([:name])
  end

  it 'handles nullable params' do
    Zodra.contract :profiles do
      action :update do
        params do
          string :bio, nullable: true
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:profiles).find_action(:update)

    result = Zodra::ParamsParser.call(
      { 'bio' => nil },
      schema: action.params
    )

    expect(result).to be_valid
    expect(result.params[:bio]).to be_nil
  end

  it 'handles default: false correctly' do
    Zodra.contract :settings do
      action :update do
        params do
          boolean :active, default: false
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:settings).find_action(:update)

    result = Zodra::ParamsParser.call({}, schema: action.params)

    expect(result).to be_valid
    expect(result.params[:active]).to be(false)
  end

  it 'coerces array params' do
    Zodra.contract :orders do
      action :batch do
        params do
          array :ids, of: :integer
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:orders).find_action(:batch)

    result = Zodra::ParamsParser.call(
      { 'ids' => %w[1 2 3] },
      schema: action.params
    )

    expect(result).to be_valid
    expect(result.params[:ids]).to eq([1, 2, 3])
  end
end
