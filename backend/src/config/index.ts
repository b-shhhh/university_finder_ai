import dotenv from "dotenv";

dotenv.config();

const parsePort = (value: string | undefined, fallback: number) => {
  const parsed = value ? Number.parseInt(value, 10) : fallback;
  return Number.isFinite(parsed) ? parsed : fallback;
};

const parseOrigins = (value: string | undefined) => {
  const defaults = [
    "http://localhost:3000",
    "http://localhost:3003",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3003"
  ];

  if (!value) return defaults;

  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean)
    .concat(defaults);
};

export const NODE_ENV = process.env.NODE_ENV || "development";
export const IS_PRODUCTION = NODE_ENV === "production";
export const PORT = parsePort(process.env.PORT, 5050);
export const MONGODB_URI = process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/university_guide";
export const JWT_SECRET = process.env.JWT_SECRET || (IS_PRODUCTION ? "" : "development_only_secret_change_me");
export const ALLOWED_ORIGINS = parseOrigins(process.env.ALLOWED_ORIGINS);
export const RATE_LIMIT_WINDOW_MS = parsePort(process.env.RATE_LIMIT_WINDOW_MS, 15 * 60 * 1000);
export const RATE_LIMIT_MAX = parsePort(process.env.RATE_LIMIT_MAX, 250);
export const COOKIE_SECURE = IS_PRODUCTION;
export const FRONTEND_URL = process.env.FRONTEND_URL || "http://localhost:3000";
export const MAIL_HOST = process.env.MAIL_HOST || "";
export const MAIL_PORT = parsePort(process.env.MAIL_PORT, 587);
export const MAIL_SECURE = process.env.MAIL_SECURE === "true";
export const MAIL_USER = process.env.MAIL_USER || "";
export const MAIL_PASS = process.env.MAIL_PASS || "";
export const MAIL_FROM = process.env.MAIL_FROM || MAIL_USER;

if (IS_PRODUCTION && (!JWT_SECRET || JWT_SECRET.length < 32)) {
  throw new Error("JWT_SECRET must be set and at least 32 characters in production");
}
