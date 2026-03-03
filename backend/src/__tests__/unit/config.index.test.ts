describe("config/index", () => {
  test("provides default JWT_SECRET in dev", () => {
    jest.resetModules();
    process.env.NODE_ENV = "development";
    delete process.env.JWT_SECRET;
    const config = require("../../config");
    expect(config.JWT_SECRET).toBeTruthy();
  });

  test("parses ALLOWED_ORIGINS list", () => {
    jest.resetModules();
    process.env.ALLOWED_ORIGINS = "http://a.com,http://b.com";
    const config = require("../../config");
    expect(config.ALLOWED_ORIGINS).toEqual(expect.arrayContaining(["http://a.com", "http://b.com"]));
  });

  test("throws in production with short JWT_SECRET", () => {
    jest.resetModules();
    process.env.NODE_ENV = "production";
    process.env.JWT_SECRET = "short";
    expect(() => require("../../config")).toThrow();
    process.env.NODE_ENV = "test";
  });
});
