import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (req: any, res: any, next: any) => {
    if (!req.headers.authorization) {
      return res.status(401).json({ success: false });
    }
    req.user = { id: "user-1" };
    next();
  },
}));

jest.mock("../../controllers/user.controller", () => ({
  getProfile: (_req: any, res: any) => res.status(200).json({ success: true, profile: { id: "user-1" } }),
  editProfile: (_req: any, res: any) => res.status(200).json({ success: true, updated: true }),
  changePassword: (_req: any, res: any) => res.status(200).json({ success: true, changed: true }),
  removeAccount: (_req: any, res: any) => res.status(200).json({ success: true, removed: true }),
}));

import app from "../../app";

describe("user integration", () => {
  test("profile requires auth", async () => {
    const res = await request(app).get("/api/users/profile");
    expect(res.status).toBe(401);
  });

  test("profile returns data when authorized", async () => {
    const res = await request(app).get("/api/users/profile").set("Authorization", "Bearer token");
    expect(res.status).toBe(200);
    expect(res.body.profile.id).toBe("user-1");
  });

  test("edit profile updates", async () => {
    const res = await request(app)
      .put("/api/users/profile")
      .set("Authorization", "Bearer token")
      .send({ fullName: "New" });
    expect(res.status).toBe(200);
    expect(res.body.updated).toBe(true);
  });

  test("change password updates", async () => {
    const res = await request(app)
      .put("/api/users/change-password")
      .set("Authorization", "Bearer token")
      .send({ oldPassword: "old", newPassword: "new" });
    expect(res.status).toBe(200);
    expect(res.body.changed).toBe(true);
  });

  test("delete profile removes account", async () => {
    const res = await request(app).delete("/api/users/profile").set("Authorization", "Bearer token");
    expect(res.status).toBe(200);
    expect(res.body.removed).toBe(true);
  });
});
