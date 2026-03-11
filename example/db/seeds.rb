# frozen_string_literal: true

# Products
products = [
  { name: 'Wireless Keyboard', sku: 'KB-001', price: 49.99, stock: 150, published: true },
  { name: 'USB-C Hub', sku: 'HUB-002', price: 34.50, stock: 75, published: true },
  { name: 'Mechanical Keyboard', sku: 'KB-003', price: 129.00, stock: 30, published: true },
  { name: 'Monitor Stand', sku: 'MS-004', price: 79.99, stock: 45, published: false },
  { name: 'Webcam HD', sku: 'WC-005', price: 59.00, stock: 0, published: false }
]

products.each do |attributes|
  Product.find_or_create_by!(sku: attributes[:sku]) do |product|
    product.assign_attributes(attributes.except(:sku))
  end
end

puts "Seeded #{Product.count} products"

# Customers
customers_data = [
  { name: 'Alice Johnson', email: 'alice@example.com', phone: '+1-555-0101', notes: nil },
  { name: 'Bob Smith', email: 'bob@example.com', phone: nil, notes: 'VIP customer' },
  { name: 'Carol Williams', email: 'carol@example.com', phone: '+1-555-0303', notes: nil }
]

customers = customers_data.map do |attributes|
  Customer.find_or_create_by!(email: attributes[:email]) do |customer|
    customer.assign_attributes(attributes.except(:email))
  end
end

puts "Seeded #{Customer.count} customers"

# Settings (singleton)
Setting.instance
puts 'Seeded settings'

# Orders
kb = Product.find_by!(sku: 'KB-001')
hub = Product.find_by!(sku: 'HUB-002')
monitor = Product.find_by!(sku: 'MS-004')

unless Order.exists?
  # Draft order
  order1 = Order.create!(customer: customers[0], shipping_address: '123 Main St, Springfield')
  order1.line_items.create!(product: kb, quantity: 2, unit_price: kb.price)
  order1.line_items.create!(product: hub, quantity: 1, unit_price: hub.price)
  order1.recalculate_total!

  # Confirmed order
  order2 = Order.create!(customer: customers[1])
  order2.line_items.create!(product: monitor, quantity: 1, unit_price: monitor.price)
  order2.recalculate_total!
  order2.confirm!

  # Cancelled order
  order3 = Order.create!(customer: customers[2], shipping_address: '456 Oak Ave, Portland')
  order3.line_items.create!(product: kb, quantity: 1, unit_price: kb.price)
  order3.recalculate_total!
  order3.cancel!

  puts "Seeded #{Order.count} orders with #{LineItem.count} line items"
end
