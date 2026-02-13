import { Request, Response } from "express";
import { AuthRequest } from "../../types/user.type";
import { adminLoginService, adminProfileService } from "../../services/admin/admin.service";

export const adminLogin = async (req: Request, res: Response) => {
  try {
    const email = Array.isArray(req.body.email) ? req.body.email[0] : req.body.email;
    const password = Array.isArray(req.body.password) ? req.body.password[0] : req.body.password;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email and password are required" });
    }

    const data = await adminLoginService(String(email), String(password));
    res.status(200).json({ success: true, token: data.token, data });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminProfile = async (req: AuthRequest, res: Response) => {
  try {
    const adminId = req.user?.id;
    if (!adminId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }
    if (req.user?.role !== "admin") {
      return res.status(403).json({ success: false, message: "Admin access required" });
    }
    const data = await adminProfileService(adminId);
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
