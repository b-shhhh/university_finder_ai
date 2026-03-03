describe("middlewares/security.middleware", () => {
  const mockRes = () => {
    const res: any = { headers: {} };
    res.setHeader = jest.fn((k: string, v: string) => {
      res.headers[k] = v;
    });
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
  };

  test("securityHeadersMiddleware sets headers", () => {
    jest.isolateModules(() => {
      const { securityHeadersMiddleware } = require("../../middlewares/security.middleware");
      const res = mockRes();
      securityHeadersMiddleware({} as any, res as any, jest.fn());
      expect(res.headers["X-Frame-Options"]).toBe("DENY");
    });
  });

  test("rateLimitMiddleware skips non-auth paths", () => {
    jest.isolateModules(() => {
      jest.doMock("../../config", () => ({ RATE_LIMIT_MAX: 1, RATE_LIMIT_WINDOW_MS: 1000 }), { virtual: true });
      const { rateLimitMiddleware } = require("../../middlewares/security.middleware");
      const next = jest.fn();
      rateLimitMiddleware({ path: "/health" } as any, {} as any, next);
      expect(next).toHaveBeenCalled();
    });
  });

  test("rateLimitMiddleware allows first request", () => {
    jest.isolateModules(() => {
      jest.doMock("../../config", () => ({ RATE_LIMIT_MAX: 1, RATE_LIMIT_WINDOW_MS: 1000 }), { virtual: true });
      const { rateLimitMiddleware } = require("../../middlewares/security.middleware");
      const next = jest.fn();
      rateLimitMiddleware({ path: "/api/auth/login", ip: "1.1.1.1" } as any, {} as any, next);
      expect(next).toHaveBeenCalled();
    });
  });

  test("rateLimitMiddleware blocks over limit", () => {
    jest.isolateModules(() => {
      const { rateLimitMiddleware } = require("../../middlewares/security.middleware");
      const res = mockRes();
      const req = { path: "/api/auth/login", ip: "2.2.2.2" } as any;
      const next = jest.fn();
      for (let i = 0; i < 260; i += 1) {
        rateLimitMiddleware(req, res as any, next);
      }
      expect(res.status).toHaveBeenCalledWith(429);
    });
  });

  test("rateLimitMiddleware isolates IPs", () => {
    jest.isolateModules(() => {
      jest.doMock("../../config", () => ({ RATE_LIMIT_MAX: 1, RATE_LIMIT_WINDOW_MS: 1000 }), { virtual: true });
      const { rateLimitMiddleware } = require("../../middlewares/security.middleware");
      const next1 = jest.fn();
      const next2 = jest.fn();
      rateLimitMiddleware({ path: "/api/auth/login", ip: "3.3.3.3" } as any, {} as any, next1);
      rateLimitMiddleware({ path: "/api/auth/login", ip: "4.4.4.4" } as any, {} as any, next2);
      expect(next1).toHaveBeenCalled();
      expect(next2).toHaveBeenCalled();
    });
  });
});
