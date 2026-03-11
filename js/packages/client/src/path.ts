export function interpolatePath(
  path: string,
  params: Record<string, unknown>,
): { url: string; remainingParams: Record<string, unknown> } {
  const remainingParams = { ...params };

  const url = path.replace(/:(\w+)/g, (_, key: string) => {
    const value = remainingParams[key];
    delete remainingParams[key];
    return encodeURIComponent(String(value));
  });

  return { url, remainingParams };
}

export function buildQueryString(
  params: Record<string, unknown>,
): string {
  const entries = Object.entries(params).filter(
    ([, value]) => value !== undefined,
  );

  if (entries.length === 0) return "";

  const searchParams = new URLSearchParams();
  for (const [key, value] of entries) {
    searchParams.set(key, String(value));
  }

  return `?${searchParams.toString()}`;
}
