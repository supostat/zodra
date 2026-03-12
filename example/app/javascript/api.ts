import { createApiClient } from "@zodra/client";
import { contracts, baseUrl } from "./types";

export const api = createApiClient({
  baseUrl,
  contracts,
});

// Usage examples (type-safe):
//
// Products
// const products = await api.products.index({});
// const product = await api.products.show({ id: "..." });
// const created = await api.products.create({ name: "Widget", sku: "WDG-001", price: 9.99, stock: 100, published: false });
// const updated = await api.products.update({ id: "...", price: 12.99 });
// await api.products.destroy({ id: "..." });
//
// Customers
// const customers = await api.customers.index({});
// const customer = await api.customers.show({ id: "..." });
// const newCustomer = await api.customers.create({ name: "Alice", email: "alice@example.com", notes: null });
// const updatedCustomer = await api.customers.update({ name: "Alice Johnson" });
// await api.customers.destroy({ id: "..." });
//
// Orders
// const orders = await api.orders.index({});
// const order = await api.orders.show({ id: "..." });
// const newOrder = await api.orders.create({ customerId: "...", items: [{ productId: "...", quantity: 2 }] });
// const confirmed = await api.orders.confirm({ id: "..." });
// const cancelled = await api.orders.cancel({ id: "..." });
// const searched = await api.orders.search({ status: "confirmed", fromDate: "2026-01-01" });
//
// Settings (singular resource)
// const settings = await api.settings.show({});
// const updatedSettings = await api.settings.update({ currency: "EUR", maintenanceMode: true });
