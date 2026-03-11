import { describe, it, expect, vi, beforeEach } from "vitest";
import { z } from "zod";
import { createApiClient } from "../src/create_api_client";
import { ZodraClientError, ZodraValidationError } from "../src/errors";

const ProductSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  price: z.number(),
});

const ShowProductsParamsSchema = z.object({
  id: z.string().uuid(),
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

function mockFetchJson(data: unknown, status = 200) {
  return vi.fn().mockResolvedValue({
    ok: status >= 200 && status < 300,
    status,
    statusText: status === 200 ? "OK" : "Error",
    json: () => Promise.resolve(data),
  });
}

describe("createApiClient", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("creates a client with contract methods", () => {
    vi.stubGlobal("fetch", mockFetchJson({}));

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    expect(api.products).toBeDefined();
    expect(typeof api.products.show).toBe("function");
    expect(typeof api.products.create).toBe("function");
    expect(typeof api.products.index).toBe("function");
  });

  it("sends GET request with path params", async () => {
    const mockFetch = mockFetchJson({
      data: { id: "abc-123", name: "Widget", price: 9.99 },
    });
    vi.stubGlobal("fetch", mockFetch);

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    await api.products.show({ id: "abc-123" });

    expect(mockFetch).toHaveBeenCalledWith(
      "http://localhost:3000/api/v1/products/abc-123",
      expect.objectContaining({ method: "GET" }),
    );
  });

  it("sends GET request with query params", async () => {
    const mockFetch = mockFetchJson({ data: [] });
    vi.stubGlobal("fetch", mockFetch);

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    await api.products.index({ page: 2 });

    expect(mockFetch).toHaveBeenCalledWith(
      "http://localhost:3000/api/v1/products?page=2",
      expect.objectContaining({ method: "GET" }),
    );
  });

  it("sends POST request with JSON body", async () => {
    const mockFetch = mockFetchJson({
      data: { id: "new-id", name: "Widget", price: 9.99 },
    });
    vi.stubGlobal("fetch", mockFetch);

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    await api.products.create({ name: "Widget", price: 9.99 });

    expect(mockFetch).toHaveBeenCalledWith(
      "http://localhost:3000/api/v1/products",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ name: "Widget", price: 9.99 }),
        headers: expect.objectContaining({
          "Content-Type": "application/json",
        }),
      }),
    );
  });

  it("returns parsed JSON response", async () => {
    const responseData = { id: "abc-123", name: "Widget", price: 9.99 };
    vi.stubGlobal("fetch", mockFetchJson({ data: responseData }));

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    const result = await api.products.show({ id: "abc-123" });

    expect(result.data).toEqual(responseData);
  });

  it("passes custom headers", async () => {
    const mockFetch = mockFetchJson({ data: {} });
    vi.stubGlobal("fetch", mockFetch);

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      headers: { Authorization: "Bearer token123" },
      contracts: { products: ProductsContract },
    });

    await api.products.index({});

    expect(mockFetch).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: "Bearer token123",
        }),
      }),
    );
  });

  it("strips trailing slash from baseUrl", async () => {
    const mockFetch = mockFetchJson({ data: {} });
    vi.stubGlobal("fetch", mockFetch);

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1/",
      contracts: { products: ProductsContract },
    });

    await api.products.index({});

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringMatching(/^http:\/\/localhost:3000\/api\/v1\/products/),
      expect.anything(),
    );
  });

  it("throws ZodraClientError on HTTP error", async () => {
    vi.stubGlobal(
      "fetch",
      mockFetchJson({ errors: ["Not found"] }, 404),
    );

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    await expect(api.products.show({ id: "missing" })).rejects.toThrow(
      ZodraClientError,
    );
  });

  it("includes status and body in HTTP error", async () => {
    vi.stubGlobal(
      "fetch",
      mockFetchJson({ errors: ["Not found"] }, 404),
    );

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
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
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it("validates params when validateParams is true", async () => {
    vi.stubGlobal("fetch", mockFetchJson({ data: {} }));

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      validateParams: true,
    });

    await expect(
      api.products.create({ name: "", price: -1 }),
    ).rejects.toThrow(ZodraValidationError);
  });

  it("skips params validation by default", async () => {
    vi.stubGlobal("fetch", mockFetchJson({ data: {} }));

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
    });

    await expect(
      api.products.create({ name: "", price: -1 }),
    ).resolves.toBeDefined();
  });

  it("validates response when validateResponse is true", async () => {
    vi.stubGlobal(
      "fetch",
      mockFetchJson({ data: { invalid: "response" } }),
    );

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
      validateResponse: true,
    });

    await expect(api.products.show({ id: "abc-123" })).rejects.toThrow(
      ZodraValidationError,
    );
  });

  it("returns validation issues in error", async () => {
    vi.stubGlobal("fetch", mockFetchJson({ data: {} }));

    const api = createApiClient({
      baseUrl: "http://localhost:3000/api/v1",
      contracts: { products: ProductsContract },
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
