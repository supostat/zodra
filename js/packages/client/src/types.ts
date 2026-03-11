import type { z } from "zod";

export type TransportRequest = {
  url: string;
  method: string;
  headers: Record<string, string>;
  body?: string;
};

export type TransportResponse = {
  status: number;
  statusText: string;
  body: unknown;
};

export type TransportFn = (
  request: TransportRequest,
) => Promise<TransportResponse>;

export type ActionDefinition = {
  method: string;
  path: string;
  params: z.ZodType<Record<string, unknown>>;
  response?: z.ZodType;
};

export type ContractDefinition = Record<string, ActionDefinition>;

type ActionClient<T extends ActionDefinition> = T extends {
  params: z.ZodType<infer P>;
  response: z.ZodType<infer R>;
}
  ? (params: P) => Promise<{ data: R }>
  : T extends { params: z.ZodType<infer P> }
    ? (params: P) => Promise<{ data: unknown }>
    : never;

export type ContractClient<T extends ContractDefinition> = {
  [K in keyof T]: ActionClient<T[K]>;
};

export type ApiClient<T extends Record<string, ContractDefinition>> = {
  [K in keyof T]: ContractClient<T[K]>;
};

export interface ApiClientConfig<
  T extends Record<string, ContractDefinition> = Record<
    string,
    ContractDefinition
  >,
> {
  baseUrl: string;
  headers?: Record<string, string>;
  contracts: T;
  transport?: TransportFn;
  validateParams?: boolean;
  validateResponse?: boolean;
}
