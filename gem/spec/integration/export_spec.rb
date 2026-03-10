# frozen_string_literal: true

RSpec.describe "Export pipeline", :acceptance do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
  end

  describe "TypeScript export" do
    it "generates interface from type DSL" do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount, min: 0
        boolean :paid, default: false
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export interface Invoice {")
      expect(result).to include("id: string;")
      expect(result).to include("number: string;")
      expect(result).to include("amount: number;")
      expect(result).to include("paid: boolean;")
    end

    it "generates enum type" do
      Zodra.enum :status, values: %i[draft sent paid overdue]

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export type Status = 'draft' | 'sent' | 'paid' | 'overdue';")
    end

    it "generates discriminated union" do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank_transfer do
          string :account_number
        end
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export type PaymentMethod =")
      expect(result).to include("type: 'card'")
      expect(result).to include("lastFour: string")
      expect(result).to include("type: 'bank_transfer'")
      expect(result).to include("accountNumber: string")
    end

    it "resolves references between types" do
      Zodra.type :customer do
        uuid :id
        string :name
      end

      Zodra.type :invoice do
        uuid :id
        reference :customer
        array :items, of: :item
      end

      Zodra.type :item do
        uuid :id
        string :description
        decimal :amount
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export interface Customer {")
      expect(result).to include("export interface Invoice {")
      expect(result).to include("customer: Customer;")
      expect(result).to include("items: Item[];")
    end

    it "handles optional and nullable fields" do
      Zodra.type :profile do
        string :name
        string? :nickname
        string :bio, nullable: true
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("name: string;")
      expect(result).to include("nickname?: string;")
      expect(result).to include("bio: null | string;")
    end
  end

  describe "Zod export" do
    it "generates schema from type DSL" do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount, min: 0
        boolean :paid, default: false
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const InvoiceSchema = z.object({")
      expect(result).to include("id: z.string().uuid()")
      expect(result).to include("number: z.string()")
      expect(result).to include("amount: z.number().min(0)")
      expect(result).to include("paid: z.boolean().default(false)")
    end

    it "generates enum schema" do
      Zodra.enum :status, values: %i[draft sent paid overdue]

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const StatusSchema = z.enum(['draft', 'sent', 'paid', 'overdue']);")
    end

    it "generates discriminated union schema" do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank_transfer do
          string :account_number
        end
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const PaymentMethodSchema = z.discriminatedUnion('type',")
      expect(result).to include("z.literal('card')")
      expect(result).to include("z.literal('bank_transfer')")
    end
  end

  describe "zod_import" do
    it "uses custom import path" do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:zod, zod_import: "zod/v4")

      expect(result).to start_with("import { z } from 'zod/v4';")
    end

    it "defaults to 'zod'" do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to start_with("import { z } from 'zod';")
    end

    it "ignores zod_import for typescript format" do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:typescript, zod_import: "zod/v4")

      expect(result).not_to include("import")
    end
  end

  describe "key_format" do
    it "transforms keys to camelCase" do
      Zodra.type :user_profile do
        string :first_name
        string :last_name
      end

      result = Zodra::Export.generate(:typescript, key_format: :camel)

      expect(result).to include("firstName: string;")
      expect(result).to include("lastName: string;")
    end
  end

  describe "contract export" do
    before do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount
      end

      Zodra.contract :invoices do
        action :create do
          post "/invoices"
          params do
            string :number, min: 1
            decimal :amount, min: 0
          end
          response :invoice
        end

        action :show do
          get "/invoices/:id"
          params do
            uuid :id
          end
          response :invoice
        end
      end
    end

    it "exports contract params as Zod schemas" do
      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const CreateInvoicesParamsSchema = z.object({")
      expect(result).to include("number: z.string().min(1)")
      expect(result).to include("amount: z.number().min(0)")
      expect(result).to include("export const ShowInvoicesParamsSchema = z.object({")
      expect(result).to include("id: z.string().uuid()")
    end

    it "exports contract descriptor as Zod" do
      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const InvoicesContract = {")
      expect(result).to include("create: { method: 'POST' as const, path: '/invoices' as const, params: CreateInvoicesParamsSchema, response: InvoiceSchema }")
      expect(result).to include("show: { method: 'GET' as const, path: '/invoices/:id' as const, params: ShowInvoicesParamsSchema, response: InvoiceSchema }")
    end

    it "exports contract params as TypeScript interfaces" do
      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export interface CreateInvoicesParams {")
      expect(result).to include("number: string;")
      expect(result).to include("export interface ShowInvoicesParams {")
      expect(result).to include("id: string;")
    end

    it "exports contract descriptor as TypeScript interface" do
      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export interface InvoicesContract {")
      expect(result).to include("create: { method: 'POST'; path: '/invoices'; params: CreateInvoicesParams; response: Invoice }")
      expect(result).to include("show: { method: 'GET'; path: '/invoices/:id'; params: ShowInvoicesParams; response: Invoice }")
    end

    it "handles action without response in descriptor" do
      Zodra.contract :search do
        action :query do
          get "/search"
          params do
            string :q, min: 1
          end
        end
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const QuerySearchParamsSchema = z.object({")
      expect(result).to include("query: { method: 'GET' as const, path: '/search' as const, params: QuerySearchParamsSchema }")
      expect(result).not_to include("query: { method: 'GET' as const, path: '/search' as const, params: QuerySearchParamsSchema, response:")
    end

    it "handles empty contract" do
      Zodra.contract :empty_resource

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const EmptyResourceContract = {} as const;")
    end
  end
end
