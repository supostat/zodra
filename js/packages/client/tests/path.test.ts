import { describe, it, expect } from "vitest";
import { interpolatePath, buildQueryString } from "../src/path";

describe("interpolatePath", () => {
  it("substitutes path parameters", () => {
    const result = interpolatePath("/products/:id", { id: "abc-123" });

    expect(result.url).toBe("/products/abc-123");
    expect(result.remainingParams).toEqual({});
  });

  it("returns remaining params after substitution", () => {
    const result = interpolatePath("/products/:id", {
      id: "abc-123",
      page: 1,
    });

    expect(result.url).toBe("/products/abc-123");
    expect(result.remainingParams).toEqual({ page: 1 });
  });

  it("handles multiple path parameters", () => {
    const result = interpolatePath("/users/:userId/posts/:postId", {
      userId: "u1",
      postId: "p2",
    });

    expect(result.url).toBe("/users/u1/posts/p2");
    expect(result.remainingParams).toEqual({});
  });

  it("encodes path parameter values", () => {
    const result = interpolatePath("/search/:query", {
      query: "hello world",
    });

    expect(result.url).toBe("/search/hello%20world");
  });

  it("returns all params when no placeholders", () => {
    const result = interpolatePath("/products", { page: 1, limit: 10 });

    expect(result.url).toBe("/products");
    expect(result.remainingParams).toEqual({ page: 1, limit: 10 });
  });
});

describe("buildQueryString", () => {
  it("builds query string from params", () => {
    const result = buildQueryString({ page: 1, limit: 10 });

    expect(result).toBe("?page=1&limit=10");
  });

  it("returns empty string for empty params", () => {
    expect(buildQueryString({})).toBe("");
  });

  it("skips undefined values", () => {
    const result = buildQueryString({ page: 1, filter: undefined });

    expect(result).toBe("?page=1");
  });
});
