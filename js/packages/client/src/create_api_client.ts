import type { z } from "zod";
import type {
  ActionDefinition,
  ApiClient,
  ApiClientConfig,
  ContractDefinition,
  TransportFn,
} from "./types";
import {
  ZodraClientError,
  ZodraValidationError,
  ZodraFieldError,
  ZodraBusinessError,
} from "./errors";
import { buildQueryString, interpolatePath } from "./path";
import { fetchTransport } from "./transport";

const BODY_METHODS = new Set(["POST", "PUT", "PATCH"]);

function isFieldErrors(body: unknown): body is { errors: Record<string, string[]> } {
  if (typeof body !== "object" || body === null || !("errors" in body)) return false;
  const { errors } = body as { errors: unknown };
  return typeof errors === "object" && errors !== null && !Array.isArray(errors);
}

function isBusinessError(body: unknown): body is { error: { code: string; message: string } } {
  if (typeof body !== "object" || body === null || !("error" in body)) return false;
  const { error } = body as { error: unknown };
  return typeof error === "object" && error !== null && "code" in error && "message" in error;
}

function parseErrorResponse(response: { status: number; statusText: string; body: unknown }): ZodraClientError {
  const { status, statusText, body } = response;

  if (isFieldErrors(body)) {
    return new ZodraFieldError(body.errors, { status, body });
  }

  if (isBusinessError(body)) {
    return new ZodraBusinessError(body.error.code, body.error.message, { status, body });
  }

  return new ZodraClientError(`HTTP ${status}: ${statusText}`, { status, body });
}

function buildActionCaller(
  baseUrl: string,
  defaultHeaders: Record<string, string>,
  action: ActionDefinition,
  transport: TransportFn,
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

    const response = await transport({ url: requestUrl, method, headers, body });

    if (response.status < 200 || response.status >= 300) {
      throw parseErrorResponse(response);
    }

    if (validateResponse && action.response) {
      const json = response.body as { data: unknown };
      const result = (action.response as z.ZodType).safeParse(json.data);
      if (!result.success) {
        throw new ZodraValidationError(
          "Response validation failed",
          result.error.issues,
        );
      }
    }

    return response.body as { data: unknown };
  };
}

function buildContractClient(
  baseUrl: string,
  defaultHeaders: Record<string, string>,
  contract: ContractDefinition,
  transport: TransportFn,
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
      transport,
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
    transport = fetchTransport,
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
      transport,
      validateParams,
      validateResponse,
    );
  }

  return client as ApiClient<T>;
}
