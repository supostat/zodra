# frozen_string_literal: true

# Example API definition — will be implemented with Zodra DSL
#
# Zodra::API.define "/api/v1" do
#   export :typescript, key_format: :camel
#   export :zod
#
#   resources :invoices, type: :invoice do
#     action :index do
#       response { body { array :invoices, of: :invoice } }
#     end
#
#     action :create do
#       request { body { partial :invoice, only: %i[number amount customer_id] } }
#       response { body { reference :invoice } }
#     end
#   end
# end
