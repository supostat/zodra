import { z } from 'zod';

export const ProductSchema = z.object({
  id: z.uuid(),
  name: z.string(),
  sku: z.string(),
  price: z.number(),
  stock: z.number().int(),
  published: z.boolean(),
});

export const IndexProductsParamsSchema = z.object({

});

export const ShowProductsParamsSchema = z.object({
  id: z.uuid(),
});

export const CreateProductsParamsSchema = z.object({
  name: z.string().min(1),
  sku: z.string().min(1),
  price: z.number().min(0),
  stock: z.number().int().min(0),
  published: z.boolean().default(false),
});

export const UpdateProductsParamsSchema = z.object({
  id: z.uuid(),
  name: z.string().min(1).optional(),
  sku: z.string().min(1).optional(),
  price: z.number().min(0).optional(),
  stock: z.number().int().min(0).optional(),
  published: z.boolean().optional(),
});

export const DestroyProductsParamsSchema = z.object({
  id: z.uuid(),
});

export const ProductsContract = {
  index: { method: 'GET' as const, path: '/api/v1/products' as const, params: IndexProductsParamsSchema, response: ProductSchema },
  show: { method: 'GET' as const, path: '/api/v1/products/:id' as const, params: ShowProductsParamsSchema, response: ProductSchema },
  create: { method: 'POST' as const, path: '/api/v1/products' as const, params: CreateProductsParamsSchema, response: ProductSchema },
  update: { method: 'PATCH' as const, path: '/api/v1/products/:id' as const, params: UpdateProductsParamsSchema, response: ProductSchema },
  destroy: { method: 'DELETE' as const, path: '/api/v1/products/:id' as const, params: DestroyProductsParamsSchema },
} as const;
