import { User } from "../models/user.model";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { FRONTEND_URL, JWT_SECRET, NODE_ENV } from "../config";
import { RegisterInput, LoginInput } from "../dtos/user.dto";
import { sendPasswordResetEmail } from "../utils/mailer";

const formatFullName = (data: RegisterInput) => {
  const fullName = data.fullName?.trim();

  if (fullName) return fullName;
  throw new Error("Full name is required");
};

const formatPhone = (data: RegisterInput) => {
  const countryCode = data.countryCode?.trim();
  const phone = data.phone.trim();
  if (!countryCode) return phone;

  return phone.startsWith(countryCode) ? phone : `${countryCode}${phone}`;
};

// Register user
export const registerUser = async (data: RegisterInput) => {
  const { password } = data;
  const email = data.email.trim().toLowerCase();

  const fullName = formatFullName(data);
  const phone = formatPhone(data);

  const existingUser = await User.findOne({ email });
  if (existingUser) throw new Error("Email already registered");

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = new User({
    fullName,
    email,
    phone,
    password: hashedPassword,
    role: "user"
  });

  await user.save();

  const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: "7d" });

  return { user, token };
};

// Login user
export const loginUser = async (data: LoginInput) => {
  const email = data.email.trim().toLowerCase();
  const { password } = data;
  const requestedRole = data.role;

  const user = await User.findOne({ email });
  if (!user) throw new Error("Invalid email or password");

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) throw new Error("Invalid email or password");
  if (requestedRole && user.role !== requestedRole) {
    throw new Error(`${requestedRole === "admin" ? "Admin" : "User"} access required`);
  }

  const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: "7d" });

  return { user, token };
};

export const whoAmIService = async (userId: string) => {
  const user = await User.findById(userId).select("-password -resetPasswordToken -resetPasswordExpires");
  if (!user) throw new Error("User not found");
  return user;
};

export const updateProfileService = async (
  userId: string,
  updates: Partial<{
    fullName: string;
    email: string;
    phone: string;
    country: string;
    bio: string;
    profilePic: string;
  }>
) => {
  const updatedUser = await User.findByIdAndUpdate(userId, updates, { returnDocument: "after" }).select(
    "-password -resetPasswordToken -resetPasswordExpires"
  );

  if (!updatedUser) throw new Error("User not found");
  return updatedUser;
};

export const requestPasswordResetService = async (email: string) => {
  const normalizedEmail = email.trim().toLowerCase();
  const user = await User.findOne({ email: normalizedEmail });
  if (!user) {
    return { success: true };
  }

  const rawToken = crypto.randomBytes(32).toString("hex");
  const hashedToken = crypto.createHash("sha256").update(rawToken).digest("hex");

  user.resetPasswordToken = hashedToken;
  user.resetPasswordExpires = new Date(Date.now() + 60 * 60 * 1000);
  await user.save();

  const resetLink = `${FRONTEND_URL.replace(/\/$/, "")}/reset-password?token=${rawToken}`;
  await sendPasswordResetEmail(normalizedEmail, resetLink);

  if (NODE_ENV !== "production") {
    return { success: true, resetToken: rawToken, resetLink };
  }

  return { success: true };
};

export const resetPasswordService = async (token: string, newPassword: string) => {
  const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

  const user = await User.findOne({
    resetPasswordToken: hashedToken,
    resetPasswordExpires: { $gt: new Date() }
  });

  if (!user) throw new Error("Invalid or expired reset token");

  user.password = await bcrypt.hash(newPassword, 10);
  user.resetPasswordToken = undefined;
  user.resetPasswordExpires = undefined;
  await user.save();

  return { success: true };
};
