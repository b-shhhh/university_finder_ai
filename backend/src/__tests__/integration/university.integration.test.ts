import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../controllers/university.controller", () => ({
  getAllUniversities: (_req: any, res: any) => res.status(200).json({ success: true, data: ["u1"] }),
  getCountries: (_req: any, res: any) => res.status(200).json({ success: true, data: ["USA"] }),
  getUniversities: (req: any, res: any) =>
    res.status(200).json({ success: true, country: req.params.country }),
  getCourses: (_req: any, res: any) => res.status(200).json({ success: true, data: ["CS"] }),
  getCoursesByCountry: (req: any, res: any) =>
    res.status(200).json({ success: true, country: req.params.course }),
  getUniversityDetail: (req: any, res: any) =>
    res.status(200).json({ success: true, id: req.params.universityId }),
  getUniversitiesByIds: (_req: any, res: any) => res.status(200).json({ success: true, data: [] }),
}));

import app from "../../app";

describe("university integration", () => {
  test("lists universities", async () => {
    const res = await request(app).get("/api/universities");
    expect(res.status).toBe(200);
    expect(res.body.data).toContain("u1");
  });

  test("gets countries", async () => {
    const res = await request(app).get("/api/universities/countries");
    expect(res.status).toBe(200);
    expect(res.body.data[0]).toBe("USA");
  });

  test("gets universities by country", async () => {
    const res = await request(app).get("/api/universities/country/Nepal");
    expect(res.status).toBe(200);
    expect(res.body.country).toBe("Nepal");
  });

  test("lists courses", async () => {
    const res = await request(app).get("/api/universities/courses");
    expect(res.status).toBe(200);
    expect(res.body.data).toContain("CS");
  });

  test("gets courses by country", async () => {
    const res = await request(app).get("/api/universities/courses/IT");
    expect(res.status).toBe(200);
    expect(res.body.country).toBe("IT");
  });

  test("gets university detail", async () => {
    const res = await request(app).get("/api/universities/123");
    expect(res.status).toBe(200);
    expect(res.body.id).toBe("123");
  });
});
