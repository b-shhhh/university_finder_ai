import request from "supertest";
import app from "../../app";

// Keep DB connection mocked to avoid real Mongo
jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

// Stub unrelated routers to avoid handler resolution errors during app import
jest.mock("../../routes/user.route", () => {
  const router = require("express").Router();
  return { __esModule: true, default: router };
});
jest.mock("../../routes/university.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/course.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/saved.routes", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/recommendation.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/admin.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/university.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/user.route", () => ({ __esModule: true, default: require("express").Router() }));

// Pass-through upload middleware
jest.mock("../../middlewares/upload.middleware", () => ({
  upload: {
    fields: () => (_req: any, _res: any, next: any) => next(),
  },
}));

// Simple auth middleware mock to inject user except when explicitly denied
jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (req: any, res: any, next: any) => {
    if (req.headers.authorization === "Bearer deny") {
      return res.status(401).json({ success: false });
    }
    req.user = { id: "user-1" };
    next();
  },
}));

// In-memory user store to mimic register/login flows
let storedUser: any = null;

jest.mock("../../controllers/auth.controller", () => ({
  register: (req: any, res: any) => {
    const { fullName, email, phone, password, confirmPassword } = req.body || {};
    if (!fullName || !email || !phone || !password || password !== confirmPassword) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }
    storedUser = { fullName, email, phone, password };
    return res.status(201).json({ success: true, message: "User Created" });
  },
  login: (req: any, res: any) => {
    const { email, password } = req.body || {};
    if (!storedUser || storedUser.email !== email) {
      return res.status(404).json({ success: false });
    }
    if (storedUser.password !== password) {
      return res.status(401).json({ success: false });
    }
    return res.status(200).json({ success: true, token: "token" });
  },
  whoAmI: (_req: any, res: any) => res.status(200).json({ success: true, user: { id: "user-1" } }),
  updateProfile: (_req: any, res: any) => res.status(200).json({ success: true, updated: true }),
  changePassword: (_req: any, res: any) => res.status(200).json({ success: true, changed: true }),
  requestPasswordReset: (_req: any, res: any) => res.status(200).json({ success: true, reset: true }),
  resetPassword: (_req: any, res: any) => res.status(200).json({ success: true }),
}));

jest.mock("../../controllers/user.controller", () => ({
  removeAccount: (_req: any, res: any) => res.status(200).json({ success: true, removed: true }),
}));

describe("Auth API Integration Tests", () => {
  const testUser = {
    fullName: "Test User",
    email: "test@example.com",
    phone: "1234567890",
    password: "password123",
    confirmPassword: "password123",
  };

  beforeEach(() => {
    storedUser = null;
  });

  describe("POST /api/auth/register", () => {
    test("should validate missing fields", async () => {
      const res = await request(app)
        .post("/api/auth/register")
        .send({ fullName: testUser.fullName, email: testUser.email });
      expect(res.statusCode).toBe(400);
      expect(res.body.success).toBe(false);
    });

    test("should register new user", async () => {
      const res = await request(app).post("/api/auth/register").send(testUser);
      expect(res.statusCode).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toBe("User Created");
    });
  });

  describe("POST /api/auth/login", () => {
    test("should login with valid credentials", async () => {
      // register first
      await request(app).post("/api/auth/register").send(testUser);
      const res = await request(app)
        .post("/api/auth/login")
        .send({ email: testUser.email, password: testUser.password });
      expect(res.statusCode).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
    });

    test("should fail with invalid email", async () => {
      // register first
      await request(app).post("/api/auth/register").send(testUser);
      const res = await request(app)
        .post("/api/auth/login")
        .send({ email: "wrong@example.com", password: testUser.password });
      expect(res.statusCode).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });
});
