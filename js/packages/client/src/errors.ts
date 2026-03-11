import type { z } from "zod";

export class ZodraClientError extends Error {
  status?: number;
  body?: unknown;

  constructor(
    message: string,
    options?: { status?: number; body?: unknown },
  ) {
    super(message);
    this.name = "ZodraClientError";
    this.status = options?.status;
    this.body = options?.body;
  }
}

export class ZodraValidationError extends ZodraClientError {
  issues: z.ZodIssue[];

  constructor(message: string, issues: z.ZodIssue[]) {
    super(message);
    this.name = "ZodraValidationError";
    this.issues = issues;
  }
}
