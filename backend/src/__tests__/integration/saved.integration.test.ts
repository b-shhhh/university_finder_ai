import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../middlewares/auth.middleware", () => ({
  authMiddleware: (_req: any, _res: any, next: any) => {
    (_req as any).user = { id: "user-1" };
    next();
  },
}));

jest.mock("../../controllers/saved.controller", () => ({
  saveUniversity: (_req: any, res: any) => res.status(201).json({ success: true, saved: true }),
  getSavedUniversities: (_req: any, res: any) => res.status(200).json({ success: true, data: ["u1"] }),
  removeSavedUniversity: (req: any, res: any) =>
    res.status(200).json({ success: true, removed: req.params.universityId }),
}));

import app from "../../app";

describe("saved universities integration", () => {
  test("save university requires auth", async () => {
    const res = await request(app).post("/api/saved-universities").send({ id: "u1" });
    expect(res.status).toBe(201);
    expect(res.body.saved).toBe(true);
  });

  test("get saved universities returns list", async () => {
    const res = await request(app).get("/api/saved-universities");
    expect(res.status).toBe(200);
    expect(res.body.data).toContain("u1");
  });

  test("remove saved university works", async () => {
    const res = await request(app).delete("/api/saved-universities/u1");
    expect(res.status).toBe(200);
    expect(res.body.removed).toBe("u1");
  });

  test("save university ignores body shape", async () => {
    const res = await request(app).post("/api/saved-universities").send({});
    expect(res.status).toBe(201);
  });
});
