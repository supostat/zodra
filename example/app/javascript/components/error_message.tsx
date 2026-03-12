import { ZodraFieldError, ZodraBusinessError, ZodraClientError } from "@zodra/client";

interface ErrorMessageProps {
  error: Error | null;
}

export function ErrorMessage({ error }: ErrorMessageProps) {
  if (!error) return null;

  if (error instanceof ZodraBusinessError) {
    return (
      <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
        <strong>{error.code}:</strong> {error.message}
      </div>
    );
  }

  if (error instanceof ZodraFieldError) {
    return (
      <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
        <ul className="list-disc pl-4">
          {Object.entries(error.errors).map(([field, messages]) => (
            <li key={field}>
              <strong>{field}:</strong> {messages.join(", ")}
            </li>
          ))}
        </ul>
      </div>
    );
  }

  if (error instanceof ZodraClientError) {
    return (
      <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
        {error.message}
      </div>
    );
  }

  return (
    <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
      {error.message}
    </div>
  );
}
