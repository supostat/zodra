import { describe, it, expect, vi } from "vitest";
import { z } from "zod";
import { createApiClient } from "../src/create_api_client";
import {
  ZodraClientError,
  ZodraValidationError,
  ZodraFieldError,
  ZodraBusinessError,
} from "../src/errors";
import type { TransportFn } from "../src/types";

const ProductSchema = z.object({
  id: z.uuid(),
  name: z.string(),
  price: z.number(),
});

const ShowProductsParamsSchema = z.object({
  id: z.uuid(),
});

const CreateProductsParamsSchema = z.object({
  name: z.string().min(1),
  price: z.number().min(0),
});

const IndexProductsParamsSchema = z.object({
  page: z.number().optional(),
});

const ProductsContract = {
  show: {
    method: "GET" as const,
    path: "/products/:id" as const,
    params: ShowProductsParamsSchema,
    response: ProductSchema,
  },
  create: {
    method: "POST" as const,
    path: "/products" as const,
    params: CreateProductsParamsSchema,
    response: ProductSchema,
  },
  index: {
    method: "GET" as const,
    path: "/products" as const,
    params: IndexProductsParamsSchema,
    response: ProductSchema,
  },
} as const;

function mockTransport(body: unknown, status = 200): TransportFn {
  return vi.fn().mockResolvedValue({
    status,
    statusText: status === 200 ? "OK" : "Error",
    body,
  });
}

describe("createApiClient", () => {
  it("creates a client with contract methods", () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({}),
    });

    expect(api.products).toBeDefined();
    expect(typeof api.products.show).toBe("function");
    expect(typeof api.products.create).toBe("function");
    expect(typeof api.products.index).toBe("function");
  });

  it("sends GET request with path params", async () => {
    const transport = mockTransport({
      data: { id: "abc-123", name: "Widget", price: 9.99 },
    });

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport,
    });

    await api.products.show({ id: "abc-123" });

    expect(transport).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "http://localhost:3000/api/v1/products/abc-123",
        method: "GET",
      }),
    );
  });

  it("sends GET request with query params", async () => {
    const transport = mockTransport({ data: [] });

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport,
    });

    await api.products.index({ page: 2 });

    expect(transport).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "http://localhost:3000/api/v1/products?page=2",
        method: "GET",
      }),
    );
  });

  it("sends POST request with JSON body", async () => {
    const transport = mockTransport({
      data: { id: "new-id", name: "Widget", price: 9.99 },
    });

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport,
    });

    await api.products.create({ name: "Widget", price: 9.99 });

    expect(transport).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "http://localhost:3000/api/v1/products",
        method: "POST",
        body: JSON.stringify({ name: "Widget", price: 9.99 }),
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    );
  });

  it("returns parsed response body", async () => {
    const responseData = { id: "abc-123", name: "Widget", price: 9.99 };

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ data: responseData }),
    });

    const result = await api.products.show({ id: "abc-123" });

    expect(result.data).toEqual(responseData);
  });

  it("passes custom headers to transport", async () => {
    const transport = mockTransport({ data: {} });

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      headers: { Authorization: "Bearer token123" },
      contracts: { products: ProductsContract },
      transport,
    });

    await api.products.index({});

    expect(transport).toHaveBeenCalledWith(
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: "Bearer token123",
        }),
      }),
    );
  });

  it("strips trailing slash from baseUrl", async () => {
    const transport = mockTransport({ data: {} });

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1/",
      contracts: { products: ProductsContract },
      transport,
    });

    await api.products.index({});

    expect(transport).toHaveBeenCalledWith(
      expect.objectContaining({
        url: expect.stringMatching(
          /^http:\/\/localhost:3000\/api\/v1\/products/,
        ),
      }),
    );
  });

  it("throws ZodraClientError on HTTP error", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ errors: ["Not found"] }, 404),
    });

    await expect(api.products.show({ id: "missing" })).rejects.toThrow(
      ZodraClientError,
    );
  });

  it("includes status and body in HTTP error", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ errors: ["Not found"] }, 404),
    });

    const error = await api.products
      .show({ id: "missing" })
      .catch((error: unknown) => error);

    expect((error as ZodraClientError).status).toBe(404);
    expect((error as ZodraClientError).body).toEqual({
      errors: ["Not found"],
    });
  });
});

describe("validation", () => {
  it("validates params when validateParams is true", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ data: {} }),
      validateParams: true,
    });

    await expect(
      api.products.create({ name: "", price: -1 }),
    ).rejects.toThrow(ZodraValidationError);
  });

  it("skips params validation by default", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ data: {} }),
    });

    await expect(
      api.products.create({ name: "", price: -1 }),
    ).resolves.toBeDefined();
  });

  it("validates response when validateResponse is true", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ data: { invalid: "response" } }),
      validateResponse: true,
    });

    await expect(api.products.show({ id: "abc-123" })).rejects.toThrow(
      ZodraValidationError,
    );
  });

  it("returns validation issues in error", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport({ data: {} }),
      validateParams: true,
    });

    const error = await api.products
      .create({ name: "", price: -1 })
      .catch((error: unknown) => error);

    expect(error).toBeInstanceOf(ZodraValidationError);
    expect(
      (error as ZodraValidationError).issues.length,
    ).toBeGreaterThan(0);
  });
});

describe("error parsing", () => {
  it("throws ZodraFieldError on 422 with field errors", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport(
        { errors: { name: ["is already taken"], price: ["must be positive"] } },
        422,
      ),
    });

    const error = await api.products
      .create({ name: "dup", price: -1 })
      .catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ZodraFieldError);
    expect((error as ZodraFieldError).errors).toEqual({
      name: ["is already taken"],
      price: ["must be positive"],
    });
    expect((error as ZodraFieldError).status).toBe(422);
  });

  it("throws ZodraBusinessError on error with code and message", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport(
        { error: { code: "already_finalized", message: "Invoice is already finalized" } },
        409,
      ),
    });

    const error = await api.products
      .show({ id: "abc-123" })
      .catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ZodraBusinessError);
    expect((error as ZodraBusinessError).code).toBe("already_finalized");
    expect((error as ZodraBusinessError).message).toBe("Invoice is already finalized");
    expect((error as ZodraBusinessError).status).toBe(409);
  });

  it("falls back to ZodraClientError for unknown error shapes", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport("Internal Server Error", 500),
    });

    const error = await api.products
      .show({ id: "abc-123" })
      .catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ZodraClientError);
    expect(error).not.toBeInstanceOf(ZodraFieldError);
    expect(error).not.toBeInstanceOf(ZodraBusinessError);
  });

  it("ZodraFieldError is instanceof ZodraClientError", async () => {
    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      transport: mockTransport(
        { errors: { name: ["taken"] } },
        422,
      ),
    });

    await expect(api.products.create({ name: "dup", price: 1 })).rejects.toThrow(
      ZodraClientError,
    );
  });
});
