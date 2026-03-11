# frozen_string_literal: true

products = [
  { name: "Wireless Keyboard", sku: "KB-001", price: 49.99, stock: 150, published: true },
  { name: "USB-C Hub", sku: "HUB-002", price: 34.50, stock: 75, published: true },
  { name: "Mechanical Keyboard", sku: "KB-003", price: 129.00, stock: 30, published: true },
  { name: "Monitor Stand", sku: "MS-004", price: 79.99, stock: 45, published: false },
  { name: "Webcam HD", sku: "WC-005", price: 59.00, stock: 0, published: false }
]

products.each do |attributes|
  Product.find_or_create_by!(sku: attributes[:sku]) do |product|
    product.assign_attributes(attributes.except(:sku))
  end
end

puts "Seeded #{Product.count} products"
