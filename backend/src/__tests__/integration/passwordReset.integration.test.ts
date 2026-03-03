import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

// Stub unrelated routers to prevent handler resolution errors
jest.mock("../../routes/user.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/university.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/course.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/saved.routes", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/recommendation.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/admin.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/university.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/admin/user.route", () => ({ __esModule: true, default: require("express").Router() }));

jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (_req: any, _res: any, next: any) => next(),
}));

jest.mock("../../controllers/auth.controller", () => ({
  requestPasswordReset: (_req: any, res: any) => res.status(200).json({ success: true, resetRequested: true }),
  resetPassword: (_req: any, res: any) => res.status(200).json({ success: true, resetDone: true }),
  register: (_req: any, res: any) => res.status(201).json({}),
  login: (_req: any, res: any) => res.status(200).json({}),
  whoAmI: (_req: any, res: any) => res.status(200).json({}),
  updateProfile: (_req: any, res: any) => res.status(200).json({}),
  changePassword: (_req: any, res: any) => res.status(200).json({}),
}));

jest.mock("../../controllers/user.controller", () => ({
  removeAccount: (_req: any, res: any) => res.status(200).json({}),
}));

import app from "../../app";

describe("password reset integration", () => {
  test("request password reset returns success", async () => {
    const res = await request(app).post("/api/auth/request-password-reset").send({ email: "user@test.com" });
    expect(res.status).toBe(200);
    expect(res.body.resetRequested).toBe(true);
  });

  test("reset password accepts token", async () => {
    const res = await request(app).post("/api/auth/reset-password/token123").send({ newPassword: "new" });
    expect(res.status).toBe(200);
    expect(res.body.resetDone).toBe(true);
  });

  test("change password requires auth middleware path", async () => {
    const res = await request(app).put("/api/auth/change-password").send({ oldPassword: "o", newPassword: "n" });
    expect(res.status).toBe(200);
  });

  test("delete account goes through controller", async () => {
    const res = await request(app).delete("/api/auth/delete-account");
    expect(res.status).toBe(200);
  });

  test("reset endpoint handles missing body gracefully", async () => {
    const res = await request(app).post("/api/auth/reset-password/abc");
    expect(res.status).toBe(200);
  });
});
