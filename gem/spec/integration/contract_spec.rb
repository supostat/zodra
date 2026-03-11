# frozen_string_literal: true

RSpec.describe 'Contract DSL', :acceptance do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  it 'defines a contract with actions via DSL' do
    Zodra.type :invoice do
      uuid :id
      string :number
      decimal :amount
    end

    Zodra.contract :invoices do
      action :create do
        params do
          string :number, min: 1
          decimal :amount, min: 0
        end
        response :invoice
      end

      action :show do
        params do
          uuid :id
        end
        response :invoice
      end
    end

    contract = Zodra::ContractRegistry.global.find!(:invoices)
    expect(contract.actions.size).to eq(2)

    create = contract.find_action(:create)
    expect(create.params.attributes.keys).to eq(%i[number amount])
    expect(create.params.attributes[:number].type).to eq(:string)
    expect(create.response_type).to eq(:invoice)

    show = contract.find_action(:show)
    expect(show.params.attributes[:id].type).to eq(:uuid)
    expect(show.response_type).to eq(:invoice)
  end

  it 'supports contract without actions' do
    Zodra.contract :empty_resource

    contract = Zodra::ContractRegistry.global.find!(:empty_resource)
    expect(contract.actions).to be_empty
  end

  it 'supports action with params only' do
    Zodra.contract :search do
      action :query do
        params do
          string :q, min: 1
          integer :page, default: 1
        end
      end
    end

    action = Zodra::ContractRegistry.global.find!(:search).find_action(:query)
    expect(action.params.attributes[:q].type).to eq(:string)
    expect(action.params.attributes[:page].default).to eq(1)
    expect(action.response_type).to be_nil
  end
end
