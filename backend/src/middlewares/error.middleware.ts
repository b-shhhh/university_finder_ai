// src/middlewares/error.middleware.ts
import { Request, Response, NextFunction } from "express";
import { HttpError } from "../error/http-error";

export const errorMiddleware = (err: any, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err); // Optional: log the error

  if (err instanceof HttpError) {
    return res.status(err.statusCode).json({ success: false, message: err.message });
  }

  // Handle multer errors
  if (err.name === "MulterError") {
    return res.status(400).json({ success: false, message: err.message });
  }

  // Handle upload file filter errors
  if (typeof err?.message === "string" && err.message.includes("Only image files are allowed")) {
    return res.status(400).json({ success: false, message: err.message });
  }

  // Default to 500 Internal Server Error
  res.status(500).json({ success: false, message: err.message || "Internal Server Error" });
};
