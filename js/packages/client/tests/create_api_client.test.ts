import { describe, it, expect } from "vitest";
import { createApiClient } from "../src/create_api_client";

describe("createApiClient", () => {
  it("returns an object", () => {
    const client = createApiClient({ baseUrl: "http://localhost:3000" });
    expect(client).toBeDefined();
  });
});
