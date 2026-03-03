import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

// Stub unrelated routers to avoid handler resolution issues
jest.mock("../../routes/user.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/university.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/course.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/saved.routes", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../routes/recommendation.route", () => ({ __esModule: true, default: require("express").Router() }));
jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (req: any, res: any, next: any) => {
    if (req.headers.authorization === "Bearer admin") {
      req.user = { id: "admin-1", role: "admin" };
      return next();
    }
    return res.status(401).json({ success: false });
  },
}));

jest.mock("../../controllers/admin/admin.controller", () => ({
  adminLogin: (_req: any, res: any) => res.status(200).json({ success: true, token: "admin-token" }),
  adminProfile: (req: any, res: any) =>
    res.status(200).json({ success: true, adminId: req.user?.id || "none" }),
}));

jest.mock("../../controllers/admin/university.controller", () => ({
  adminListUniversities: (_req: any, res: any) => res.status(200).json({ success: true, universities: [] }),
  adminGetUniversity: (_req: any, res: any) => res.status(200).json({ success: true, university: { id: "u1" } }),
  adminCreateUniversity: (_req: any, res: any) => res.status(201).json({ success: true, created: true }),
  adminUpdateUniversity: (_req: any, res: any) => res.status(200).json({ success: true, updated: true }),
  adminDeleteUniversity: (_req: any, res: any) => res.status(200).json({ success: true, deleted: true }),
}));

jest.mock("../../controllers/admin/user.controller", () => ({
  adminListUsers: (_req: any, res: any) => res.status(200).json({ success: true, users: [] }),
  adminGetUser: (_req: any, res: any) => res.status(200).json({ success: true, user: { id: "u1" } }),
  adminUpdateUser: (_req: any, res: any) => res.status(200).json({ success: true, updated: true }),
  adminDeleteUser: (_req: any, res: any) => res.status(200).json({ success: true, deleted: true }),
}));

import app from "../../app";

describe("admin integration", () => {
  test("admin login returns token", async () => {
    const res = await request(app).post("/api/admin/login").send({ email: "admin@test.com", password: "pw" });
    expect(res.status).toBe(200);
    expect(res.body.token).toBe("admin-token");
  });

  test("admin profile requires admin token", async () => {
    const res = await request(app).get("/api/admin/profile");
    expect(res.status).toBe(401);
  });

  test("admin profile succeeds with token", async () => {
    const res = await request(app).get("/api/admin/profile").set("Authorization", "Bearer admin");
    expect(res.status).toBe(200);
    expect(res.body.adminId).toBe("admin-1");
  });

  test("admin create university route works", async () => {
    const res = await request(app)
      .post("/api/admin/universities")
      .set("Authorization", "Bearer admin")
      .send({ name: "Test" });
    expect(res.status).toBe(201);
  });

  test("admin update university route works", async () => {
    const res = await request(app)
      .put("/api/admin/universities/123")
      .set("Authorization", "Bearer admin")
      .send({ name: "Updated" });
    expect(res.status).toBe(200);
  });

  test("admin delete university route works", async () => {
    const res = await request(app)
      .delete("/api/admin/universities/123")
      .set("Authorization", "Bearer admin");
    expect(res.status).toBe(200);
  });

  test("admin list users route works", async () => {
    const res = await request(app)
      .get("/api/admin/users")
      .set("Authorization", "Bearer admin");
    expect(res.status).toBe(200);
    expect(res.body.users).toEqual([]);
  });

  test("admin unauthorized returns 401", async () => {
    const res = await request(app).get("/api/admin/users");
    expect(res.status).toBe(401);
  });
});
