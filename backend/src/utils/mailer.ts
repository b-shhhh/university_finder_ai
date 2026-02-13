import nodemailer from "nodemailer";
import { IS_PRODUCTION, MAIL_FROM, MAIL_HOST, MAIL_PASS, MAIL_PORT, MAIL_SECURE, MAIL_USER } from "../config";

const isMailerConfigured = () => {
  return Boolean(MAIL_HOST && MAIL_PORT && MAIL_USER && MAIL_PASS && MAIL_FROM);
};

let transporter: nodemailer.Transporter | null = null;

const getTransporter = () => {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: MAIL_HOST,
      port: MAIL_PORT,
      secure: MAIL_SECURE,
      auth: {
        user: MAIL_USER,
        pass: MAIL_PASS
      }
    });
  }
  return transporter;
};

export const sendPasswordResetEmail = async (to: string, resetLink: string) => {
  if (!isMailerConfigured()) {
    const message = `[Mail not configured] Password reset link for ${to}: ${resetLink}`;
    if (IS_PRODUCTION) {
      throw new Error("Mailer is not configured");
    }
    console.log(message);
    return;
  }

  const html = `
    <div style="font-family: Arial, sans-serif; line-height: 1.5;">
      <h2>Password Reset Request</h2>
      <p>You requested a password reset for your account.</p>
      <p>Click the link below to set a new password:</p>
      <p><a href="${resetLink}" target="_blank" rel="noopener noreferrer">${resetLink}</a></p>
      <p>This link will expire in 1 hour.</p>
      <p>If you did not request this, you can ignore this email.</p>
    </div>
  `;

  await getTransporter().sendMail({
    from: MAIL_FROM,
    to,
    subject: "Reset your password",
    html
  });
};

