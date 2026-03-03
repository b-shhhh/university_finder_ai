import { errorMiddleware } from "../../middlewares/error.middleware";
import { HttpError } from "../../error/http-error";

const mockRes = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

let errorSpy: jest.SpyInstance;

beforeAll(() => {
  errorSpy = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterAll(() => {
  errorSpy.mockRestore();
});

describe("middlewares/error.middleware", () => {
  test("formats HttpError", () => {
    const res = mockRes();
    errorMiddleware(new HttpError("bad", 418), {} as any, res as any, jest.fn());
    expect(res.status).toHaveBeenCalledWith(418);
    expect(res.json).toHaveBeenCalledWith({ success: false, message: "bad" });
  });

  test("handles multer error", () => {
    const res = mockRes();
    errorMiddleware({ name: "MulterError", message: "file too big" }, {} as any, res as any, jest.fn());
    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("defaults to 500", () => {
    const res = mockRes();
    errorMiddleware(new Error("boom"), {} as any, res as any, jest.fn());
    expect(res.status).toHaveBeenCalledWith(500);
  });
});
