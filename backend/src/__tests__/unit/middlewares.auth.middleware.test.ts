import jwt from "jsonwebtoken";
import { authMiddleware } from "../../middlewares/auth.middleware";

jest.mock("jsonwebtoken", () => ({
  verify: jest.fn()
}));

const mockRes = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe("middlewares/auth.middleware", () => {
  test("rejects missing token", () => {
    const res = mockRes();
    authMiddleware({ headers: {} } as any, res as any, jest.fn());
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test("accepts valid token", () => {
    (jwt.verify as jest.Mock).mockReturnValue({ id: "1" });
    const res = mockRes();
    const next = jest.fn();
    authMiddleware({ headers: { authorization: "Bearer token" } } as any, res as any, next);
    expect(next).toHaveBeenCalled();
  });

  test("rejects invalid token", () => {
    (jwt.verify as jest.Mock).mockImplementation(() => {
      throw new Error("bad");
    });
    const res = mockRes();
    authMiddleware({ headers: { authorization: "Bearer bad" } } as any, res as any, jest.fn());
    expect(res.status).toHaveBeenCalledWith(401);
  });

  test("reads token from cookies", () => {
    (jwt.verify as jest.Mock).mockReturnValue({ id: "cookie-id" });
    const res = mockRes();
    const next = jest.fn();
    authMiddleware({ headers: { cookie: "auth_token=abc; foo=bar" } } as any, res as any, next);
    expect(next).toHaveBeenCalled();
  });

  test("prefers header over cookie", () => {
    (jwt.verify as jest.Mock).mockReturnValue({ id: "header-id" });
    const res = mockRes();
    const next = jest.fn();
    authMiddleware(
      { headers: { authorization: "Bearer header", cookie: "auth_token=cookie" } } as any,
      res as any,
      next
    );
    expect(jwt.verify).toHaveBeenCalledWith("header", expect.anything());
  });
});
