import { NextFunction, Request, Response } from "express";
import { RATE_LIMIT_MAX, RATE_LIMIT_WINDOW_MS } from "../config";

type Entry = {
  count: number;
  resetAt: number;
};

const ipStore = new Map<string, Entry>();

const now = () => Date.now();

const getIp = (req: Request) => req.ip || req.socket.remoteAddress || "unknown";

const isSensitivePath = (path: string) => path.startsWith("/api/auth");

export const securityHeadersMiddleware = (_req: Request, res: Response, next: NextFunction) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader("X-XSS-Protection", "1; mode=block");
  next();
};

export const rateLimitMiddleware = (req: Request, res: Response, next: NextFunction) => {
  if (!isSensitivePath(req.path)) {
    return next();
  }

  const ip = getIp(req);
  const current = ipStore.get(ip);
  const ts = now();

  if (!current || ts > current.resetAt) {
    ipStore.set(ip, { count: 1, resetAt: ts + RATE_LIMIT_WINDOW_MS });
    return next();
  }

  current.count += 1;
  ipStore.set(ip, current);

  if (current.count > RATE_LIMIT_MAX) {
    const retryAfter = Math.max(1, Math.ceil((current.resetAt - ts) / 1000));
    res.setHeader("Retry-After", String(retryAfter));
    return res.status(429).json({
      success: false,
      message: "Too many requests. Please try again later."
    });
  }

  return next();
};
