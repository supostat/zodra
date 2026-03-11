import type { TransportFn } from "./types";

export const fetchTransport: TransportFn = async ({
  url,
  method,
  headers,
  body,
}) => {
  const response = await fetch(url, { method, headers, body });
  const responseBody = await response.json().catch(() => undefined);

  return {
    status: response.status,
    statusText: response.statusText,
    body: responseBody,
  };
};
