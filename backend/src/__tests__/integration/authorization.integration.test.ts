import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (req: any, res: any, next: any) => {
    const token = req.headers.authorization || "";
    if (token === "Bearer admin") {
      req.user = { id: "admin-1", role: "admin" };
      return next();
    }
    if (token.startsWith("Bearer")) {
      req.user = { id: "user-1", role: "user" };
      return next();
    }
    return res.status(401).json({ success: false, message: "No token provided" });
  },
}));

jest.mock("../../controllers/admin/admin.controller", () => ({
  adminLogin: (_req: any, res: any) => res.status(200).json({ success: true, admin: true }),
  adminProfile: (req: any, res: any) =>
    res.status(200).json({ success: true, adminId: req.user?.id || "none" }),
}));

import app from "../../app";

describe("authorization integration", () => {
  test("admin login succeeds without auth", async () => {
    const res = await request(app).post("/api/admin/login").send({ email: "admin@test.com", password: "pw" });
    expect(res.status).toBe(200);
    expect(res.body.admin).toBe(true);
  });

  test("admin profile requires token", async () => {
    const res = await request(app).get("/api/admin/profile");
    expect(res.status).toBe(401);
  });

  test("admin profile works with admin token", async () => {
    const res = await request(app).get("/api/admin/profile").set("Authorization", "Bearer admin");
    expect(res.status).toBe(200);
    expect(res.body.adminId).toBe("admin-1");
  });

  test("admin profile passes through for user token", async () => {
    const res = await request(app).get("/api/admin/profile").set("Authorization", "Bearer usertoken");
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test("auth middleware attaches role", async () => {
    const res = await request(app).get("/api/admin/profile").set("Authorization", "Bearer admin");
    expect(res.body.adminId).toBe("admin-1");
  });
});
