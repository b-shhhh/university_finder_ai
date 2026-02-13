import { Request, Response } from "express";
import { AuthRequest } from "../types/user.type";
import {
  registerUser,
  loginUser,
  whoAmIService,
  updateProfileService,
  requestPasswordResetService,
  resetPasswordService
} from "../services/auth.service";
import { registerSchema, loginSchema } from "../dtos/user.dto";
import bcrypt from "bcrypt";
import { User } from "../models/user.model";

const userPayload = (user: any) => ({
  id: user._id,
  fullName: user.fullName,
  email: user.email,
  phone: user.phone,
  country: user.country,
  bio: user.bio,
  role: user.role,
  profilePic: user.profilePic
});

export const register = async (req: Request, res: Response) => {
  try {
    const parsed = registerSchema.parse(req.body);
    const { user, token } = await registerUser(parsed);

    res.status(201).json({
      success: true,
      token,
      data: {
        user: userPayload(user),
        token
      }
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const parsed = loginSchema.parse(req.body);
    const { user, token } = await loginUser(parsed);

    res.status(200).json({
      success: true,
      token,
      data: {
        user: userPayload(user),
        token
      }
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const whoAmI = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) throw new Error("Unauthorized");

    const user = await whoAmIService(userId);
    res.status(200).json({ success: true, data: user });
  } catch (error: any) {
    res.status(401).json({ success: false, message: error.message });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) throw new Error("Unauthorized");

    const body = req.body || {};
    const updates: any = { ...body };

    const rawName = body.fullName || body.name || body.username;
    if (rawName) {
      updates.fullName = String(rawName).trim();
      delete updates.name;
      delete updates.username;
    }

    if (body.countryCode && body.phone) {
      const cc = String(body.countryCode).trim();
      const phone = String(body.phone).trim();
      updates.phone = phone.startsWith(cc) ? phone : `${cc}${phone}`;
      delete updates.countryCode;
    }

    const fileMap = (req.files as Record<string, Express.Multer.File[] | undefined>) || {};
    const uploadedProfilePic = fileMap.profilePic?.[0] || fileMap.profileImage?.[0];
    if (uploadedProfilePic?.filename) {
      updates.profilePic = `/uploads/${uploadedProfilePic.filename}`;
    }

    // Do not overwrite persisted values with blank strings from optional form fields.
    Object.keys(updates).forEach((key) => {
      if (typeof updates[key] === "string") {
        const trimmed = updates[key].trim();
        if (!trimmed) {
          delete updates[key];
          return;
        }
        updates[key] = trimmed;
      }
    });

    const updatedUser = await updateProfileService(userId, updates);
    res.status(200).json({ success: true, data: updatedUser });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const changePassword = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const oldPassword = req.body?.oldPassword || req.body?.currentPassword;
    const newPassword = req.body?.newPassword;

    if (!userId) throw new Error("Unauthorized");
    if (!oldPassword || !newPassword) throw new Error("Old and new passwords required");

    const user = await User.findById(userId);
    if (!user) throw new Error("User not found");

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) throw new Error("Old password incorrect");

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.status(200).json({ success: true, message: "Password changed successfully" });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const requestPasswordReset = async (req: Request, res: Response) => {
  try {
    const email = Array.isArray(req.body.email) ? req.body.email[0] : req.body.email;
    if (!email) throw new Error("Email is required");

    const data = await requestPasswordResetService(email);
    const devResponse = process.env.NODE_ENV !== "production" && data.resetToken
      ? { resetToken: data.resetToken }
      : {};

    res.status(200).json({
      success: true,
      message: "If the email exists, a reset flow has been initiated",
      ...devResponse
    });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const resetPassword = async (req: Request, res: Response) => {
  try {
    const token = Array.isArray(req.params.token) ? req.params.token[0] : req.params.token;
    const newPassword = Array.isArray(req.body.newPassword) ? req.body.newPassword[0] : req.body.newPassword;

    if (!token || !newPassword) throw new Error("Token and newPassword are required");

    await resetPasswordService(token, newPassword);
    res.status(200).json({ success: true, message: "Password has been reset successfully" });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
