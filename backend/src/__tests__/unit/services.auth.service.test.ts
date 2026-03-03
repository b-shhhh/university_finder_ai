import bcrypt from "bcrypt";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { registerUser, loginUser, requestPasswordResetService, resetPasswordService } from "../../services/auth.service";

jest.mock("../../models/user.model", () => {
  const MockUser: any = function (this: any, data: any) {
    Object.assign(this, data);
    this._id = "new-id";
    this.save = jest.fn().mockResolvedValue(this);
  };
  MockUser.findOne = jest.fn();
  MockUser.findById = jest.fn();
  return { User: MockUser };
});

jest.mock("../../utils/mailer", () => ({
  sendPasswordResetEmail: jest.fn()
}));

jest.mock("bcrypt", () => ({
  hash: jest.fn(async (v: string) => `hashed-${v}`),
  compare: jest.fn(async (a: string, b: string) => a === b)
}));

jest.mock("jsonwebtoken", () => ({
  sign: jest.fn(() => "jwt-token")
}));

jest.mock("crypto");

const { User }: any = require("../../models/user.model");
const { sendPasswordResetEmail } = require("../../utils/mailer");

describe("services/auth.service", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("registerUser hashes password and returns token", async () => {
    User.findOne.mockResolvedValue(null);
    const result = await registerUser({
      fullName: "Jane Doe",
      email: "Jane@Example.com",
      phone: "12345",
      password: "secret",
      countryCode: "+1"
    } as any);
    expect(result.token).toBe("jwt-token");
    expect(result.user.password).toBe("hashed-secret");
  });

  test("registerUser rejects duplicate email", async () => {
    User.findOne.mockResolvedValue({ id: "exists" });
    await expect(
      registerUser({ fullName: "x", email: "a@b.com", phone: "1", password: "secret", countryCode: "+1" } as any)
    ).rejects.toThrow(/already registered/i);
  });

  test("loginUser rejects unknown email", async () => {
    User.findOne.mockResolvedValue(null);
    await expect(loginUser({ email: "none@b.com", password: "x" } as any)).rejects.toThrow();
  });

  test("loginUser rejects bad password", async () => {
    User.findOne.mockResolvedValue({ password: "hashed" });
    (bcrypt.compare as jest.Mock).mockResolvedValue(false);
    await expect(loginUser({ email: "a@b.com", password: "wrong" } as any)).rejects.toThrow();
  });

  test("requestPasswordResetService returns success when missing user", async () => {
    User.findOne.mockResolvedValue(null);
    const res = await requestPasswordResetService("none@test.com");
    expect(res.success).toBe(true);
    expect(sendPasswordResetEmail).not.toHaveBeenCalled();
  });

  test("requestPasswordResetService sends email when user exists", async () => {
    const save = jest.fn();
    User.findOne.mockResolvedValue({ save });
    (crypto.randomBytes as jest.Mock).mockReturnValue({ toString: () => "raw" });
    (crypto.createHash as jest.Mock).mockReturnValue({
      update: () => ({ digest: () => "hashed" })
    });
    const res = await requestPasswordResetService("user@test.com");
    expect(save).toHaveBeenCalled();
    expect(res.resetToken).toBe("raw");
    expect(sendPasswordResetEmail).toHaveBeenCalled();
  });

  test("resetPasswordService throws for invalid token", async () => {
    (crypto.createHash as jest.Mock).mockReturnValue({
      update: () => ({ digest: () => "hashed" })
    });
    User.findOne.mockResolvedValue(null);
    await expect(resetPasswordService("token", "new")).rejects.toThrow(/invalid or expired/i);
  });
});
