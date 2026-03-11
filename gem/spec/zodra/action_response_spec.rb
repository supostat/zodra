# frozen_string_literal: true

RSpec.describe "Action response definition" do
  after do
    Zodra::ContractRegistry.global.clear!
    Zodra::TypeRegistry.global.clear!
  end

  it "defines inline response with block" do
    contract = Zodra.contract :invoices do
      action :show do
        get "/invoices/:id"
        response do
          string :number
          decimal :amount
        end
      end
    end

    action = contract.find_action(:show)
    schema = action.response_schema

    expect(schema.attributes.keys).to eq(%i[number amount])
  end

  it "references global type with symbol" do
    Zodra.type :invoice do
      string :number
    end

    contract = Zodra.contract :invoices do
      action :show do
        get "/invoices/:id"
        response :invoice
      end
    end

    action = contract.find_action(:show)
    schema = action.response_schema

    expect(schema.attributes.keys).to eq([:number])
  end

  it "references contract-scoped type with symbol" do
    contract = Zodra.contract :invoices do
      type :invoice do
        string :number
        decimal :amount
      end

      action :show do
        get "/invoices/:id"
        response :invoice
      end
    end

    action = contract.find_action(:show)
    schema = action.response_schema

    expect(schema.attributes.keys).to eq(%i[number amount])
  end

  it "marks action as collection" do
    contract = Zodra.contract :invoices do
      action :index do
        get "/invoices"
        response(collection: true) do
          string :number
          decimal :amount
        end
      end
    end

    action = contract.find_action(:index)
    expect(action.collection?).to be true
  end

  it "defaults to non-collection" do
    contract = Zodra.contract :invoices do
      action :show do
        get "/invoices/:id"
        response do
          string :number
        end
      end
    end

    action = contract.find_action(:show)
    expect(action.collection?).to be false
  end

  it "supports compound response with references" do
    Zodra.type :rota_shift do
      string :date
      string :employee
    end

    contract = Zodra.contract :invoices do
      type :invoice do
        string :number
      end

      action :create do
        post "/invoices"
        response do
          reference :invoice
          array :rota_shifts, of: :rota_shift
        end
      end
    end

    action = contract.find_action(:create)
    schema = action.response_schema

    expect(schema.attributes.keys).to eq(%i[invoice rota_shifts])
  end
end
