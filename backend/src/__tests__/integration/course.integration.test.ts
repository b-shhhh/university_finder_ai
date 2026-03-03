import request from "supertest";

jest.mock("../../database/mongodb", () => ({
  connectDatabase: jest.fn().mockResolvedValue(undefined),
}));

jest.mock("../../controllers/course.controller", () => ({
  listCourses: (_req: any, res: any) => res.status(200).json({ success: true, data: ["CS", "IT"] }),
  coursesByCountry: (req: any, res: any) =>
    res.status(200).json({ success: true, country: req.params.country }),
  courseDetails: (req: any, res: any) =>
    res.status(200).json({ success: true, id: req.params.id }),
  countriesByCourse: (req: any, res: any) =>
    res.status(200).json({ success: true, course: req.params.id, countries: ["US"] }),
}));

import app from "../../app";

describe("course integration", () => {
  test("lists courses", async () => {
    const res = await request(app).get("/api/courses");
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  test("courses by country", async () => {
    const res = await request(app).get("/api/courses/country/USA");
    expect(res.status).toBe(200);
    expect(res.body.country).toBe("USA");
  });

  test("course details", async () => {
    const res = await request(app).get("/api/courses/123");
    expect(res.status).toBe(200);
    expect(res.body.id).toBe("123");
  });

  test("countries by course", async () => {
    const res = await request(app).get("/api/courses/123/countries");
    expect(res.status).toBe(200);
    expect(res.body.course).toBe("123");
  });

  test("courses endpoint supports json body", async () => {
    const res = await request(app).get("/api/courses").send({ sample: true });
    expect(res.status).toBe(200);
  });
});
