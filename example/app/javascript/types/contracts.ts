import { ProductsContract } from './schemas';

export const contracts = {
  products: ProductsContract,
} as const;

export const baseUrl = '/api/v1';
