import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../controllers/recommendation.controller", () => ({
  getRecommendations: (_req: any, res: any) =>
    res.status(200).json({ success: true, recommendations: ["uni-1"] }),
}));

import app from "../../app";

describe("recommendation integration", () => {
  test("returns recommendations", async () => {
    const res = await request(app).get("/api/recommendations");
    expect(res.status).toBe(200);
    expect(res.body.recommendations).toContain("uni-1");
  });

  test("supports query params", async () => {
    const res = await request(app).get("/api/recommendations?country=US&course=CS");
    expect(res.status).toBe(200);
  });

  test("returns json content-type", async () => {
    const res = await request(app).get("/api/recommendations");
    expect(res.headers["content-type"]).toMatch(/json/);
  });

  test("handles empty body", async () => {
    const res = await request(app).get("/api/recommendations").send({});
    expect(res.status).toBe(200);
  });
});
