import { createApiClient } from "@zodra/client";
import { contracts, baseUrl } from "./types/contracts";

export const api = createApiClient({
  baseUrl,
  contracts,
});

// Usage examples (type-safe):
//
// const products = await api.products.index({});
// const product = await api.products.show({ id: "..." });
// const created = await api.products.create({ name: "Widget", sku: "WDG-001", price: 9.99, stock: 100 });
// const updated = await api.products.update({ id: "...", price: 12.99 });
// await api.products.destroy({ id: "..." });
