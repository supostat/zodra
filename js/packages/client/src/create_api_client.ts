import type { z } from "zod";
import type {
  ActionDefinition,
  ApiClient,
  ApiClientConfig,
  ContractDefinition,
} from "./types";
import { ZodraClientError, ZodraValidationError } from "./errors";
import { buildQueryString, interpolatePath } from "./path";

const BODY_METHODS = new Set(["POST", "PUT", "PATCH"]);

function buildActionCaller(
  baseUrl: string,
  defaultHeaders: Record<string, string>,
  action: ActionDefinition,
  validateParams: boolean,
  validateResponse: boolean,
): (params: Record<string, unknown>) => Promise<{ data: unknown }> {
  return async (params: Record<string, unknown>) => {
    if (validateParams) {
      const result = action.params.safeParse(params);
      if (!result.success) {
        throw new ZodraValidationError(
          "Params validation failed",
          result.error.issues,
        );
      }
    }

    const method = action.method;
    const { url, remainingParams } = interpolatePath(action.path, params);
    const fullUrl = `${baseUrl}${url}`;

    const headers: Record<string, string> = { ...defaultHeaders };
    let requestUrl = fullUrl;
    let body: string | undefined;

    if (BODY_METHODS.has(method)) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(remainingParams);
    } else {
      requestUrl = `${fullUrl}${buildQueryString(remainingParams)}`;
    }

    const response = await fetch(requestUrl, { method, headers, body });

    if (!response.ok) {
      const responseBody = await response.json().catch(() => undefined);
      throw new ZodraClientError(
        `HTTP ${response.status}: ${response.statusText}`,
        { status: response.status, body: responseBody },
      );
    }

    const json = await response.json();

    if (validateResponse && action.response) {
      const result = (action.response as z.ZodType).safeParse(json.data);
      if (!result.success) {
        throw new ZodraValidationError(
          "Response validation failed",
          result.error.issues,
        );
      }
    }

    return json;
  };
}

function buildContractClient(
  baseUrl: string,
  defaultHeaders: Record<string, string>,
  contract: ContractDefinition,
  validateParams: boolean,
  validateResponse: boolean,
): Record<string, (params: Record<string, unknown>) => Promise<unknown>> {
  const client: Record<
    string,
    (params: Record<string, unknown>) => Promise<unknown>
  > = {};

  for (const [actionName, action] of Object.entries(contract)) {
    client[actionName] = buildActionCaller(
      baseUrl,
      defaultHeaders,
      action,
      validateParams,
      validateResponse,
    );
  }

  return client;
}

export function createApiClient<
  T extends Record<string, ContractDefinition>,
>(config: ApiClientConfig<T>): ApiClient<T> {
  const {
    baseUrl,
    headers = {},
    contracts,
    validateParams = false,
    validateResponse = false,
  } = config;

  const normalizedBaseUrl = baseUrl.replace(/\/+$/, "");
  const client: Record<string, unknown> = {};

  for (const [contractName, contract] of Object.entries(contracts)) {
    client[contractName] = buildContractClient(
      normalizedBaseUrl,
      headers,
      contract,
      validateParams,
      validateResponse,
    );
  }

  return client as ApiClient<T>;
}
