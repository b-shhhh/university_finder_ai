// src/errors/http-error.ts

export class HttpError extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number = 400) {
    super(message);
    this.statusCode = statusCode;

    // Set the prototype explicitly (needed for custom errors in TypeScript)
    Object.setPrototypeOf(this, HttpError.prototype);
  }
}
