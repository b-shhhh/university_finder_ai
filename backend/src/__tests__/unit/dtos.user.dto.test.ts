import { loginSchema, registerSchema } from "../../dtos/user.dto";

describe("dtos/user.dto", () => {
  test("registerSchema requires fullName", () => {
    expect(() =>
      registerSchema.parse({ email: "a@b.com", phone: "1234567", password: "secret" })
    ).toThrow();
  });

  test("registerSchema enforces password match", () => {
    expect(() =>
      registerSchema.parse({
        fullName: "Jane",
        email: "a@b.com",
        phone: "1234567",
        password: "secret",
        confirmPassword: "different"
      })
    ).toThrow(/passwords do not match/i);
  });

  test("registerSchema accepts valid payload", () => {
    const data = registerSchema.parse({
      fullName: "Jane",
      email: "a@b.com",
      phone: "1234567",
      password: "secret",
      confirmPassword: "secret",
      countryCode: "+1"
    });
    expect(data.fullName).toBe("Jane");
  });

  test("loginSchema validates email", () => {
    expect(() => loginSchema.parse({ email: "bad", password: "secret" })).toThrow();
  });

  test("loginSchema accepts optional role", () => {
    const parsed = loginSchema.parse({ email: "ok@ok.com", password: "abcdef", role: "admin" });
    expect(parsed.role).toBe("admin");
  });

  test("loginSchema rejects short password", () => {
    expect(() => loginSchema.parse({ email: "ok@ok.com", password: "123" })).toThrow();
  });
});
