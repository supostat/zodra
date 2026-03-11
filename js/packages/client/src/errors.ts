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

export class ZodraFieldError extends ZodraClientError {
  errors: Record<string, string[]>;

  constructor(
    errors: Record<string, string[]>,
    options?: { status?: number; body?: unknown },
  ) {
    super("Validation failed", options);
    this.name = "ZodraFieldError";
    this.errors = errors;
  }
}

export class ZodraBusinessError extends ZodraClientError {
  code: string;

  constructor(
    code: string,
    message: string,
    options?: { status?: number; body?: unknown },
  ) {
    super(message, options);
    this.name = "ZodraBusinessError";
    this.code = code;
  }
}
