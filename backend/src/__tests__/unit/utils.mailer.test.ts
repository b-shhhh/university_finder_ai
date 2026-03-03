describe("utils/mailer", () => {
  beforeEach(() => {
    jest.resetModules();
    process.env.NODE_ENV = "test";
    delete process.env.MAIL_HOST;
    delete process.env.MAIL_USER;
    delete process.env.MAIL_PASS;
    delete process.env.MAIL_FROM;
  });

  test("logs when not configured in dev", async () => {
    process.env.NODE_ENV = "development";
    process.env.MAIL_HOST = "";
    process.env.MAIL_USER = "";
    process.env.MAIL_PASS = "";
    process.env.MAIL_FROM = "";
    jest.doMock("nodemailer", () => ({ createTransport: jest.fn(() => ({ sendMail: jest.fn() })) }));
    const nodemailer = require("nodemailer");
    const { sendPasswordResetEmail } = require("../../utils/mailer");
    await expect(sendPasswordResetEmail("user@test.com", "link")).resolves.not.toThrow();
    expect(nodemailer.createTransport).not.toHaveBeenCalled();
  });

  test("sends when configured", async () => {
    const sendMail = jest.fn();
    process.env.NODE_ENV = "development";
    process.env.MAIL_HOST = "smtp.test";
    process.env.MAIL_USER = "user";
    process.env.MAIL_PASS = "pass";
    process.env.MAIL_FROM = "from@test.com";
    jest.doMock("nodemailer", () => ({ createTransport: jest.fn(() => ({ sendMail })) }));
    const { sendPasswordResetEmail } = require("../../utils/mailer");
    await sendPasswordResetEmail("user@test.com", "link");
    expect(sendMail).toHaveBeenCalled();
  });

  test("throws in production without config", async () => {
    process.env.NODE_ENV = "production";
    process.env.MAIL_HOST = "";
    process.env.MAIL_USER = "";
    process.env.MAIL_PASS = "";
    process.env.MAIL_FROM = "";
    jest.doMock("nodemailer", () => ({ createTransport: jest.fn(() => ({ sendMail: jest.fn() })) }));
    const { sendPasswordResetEmail } = require("../../utils/mailer");
    await expect(sendPasswordResetEmail("user@test.com", "link")).rejects.toThrow(/mailer is not configured/i);
  });

  test("reuses transporter", async () => {
    const sendMail = jest.fn();
    const createTransport = jest.fn(() => ({ sendMail }));
    process.env.NODE_ENV = "development";
    process.env.MAIL_HOST = "smtp.test";
    process.env.MAIL_USER = "user";
    process.env.MAIL_PASS = "pass";
    process.env.MAIL_FROM = "from@test.com";
    jest.doMock("nodemailer", () => ({ createTransport }));
    const { sendPasswordResetEmail } = require("../../utils/mailer");
    await sendPasswordResetEmail("user@test.com", "link");
    await sendPasswordResetEmail("user@test.com", "link");
    expect(createTransport).toHaveBeenCalledTimes(1);
  });
});
