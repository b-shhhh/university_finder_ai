import { Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../config";
import { AuthRequest } from "../types/user.type";

export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  const tokenFromHeader = authHeader?.startsWith("Bearer ") ? authHeader.split(" ")[1] : null;
  const cookieHeader = req.headers.cookie || "";
  const tokenFromCookie =
    cookieHeader
      .split(";")
      .map((part) => part.trim())
      .find((part) => part.startsWith("auth_token="))
      ?.split("=")[1] || null;
  const token = tokenFromHeader || tokenFromCookie;
  if (!token) {
    return res.status(401).json({ success: false, message: "No token provided" });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { id: string; role?: "user" | "admin" };
    req.user = { id: decoded.id, role: decoded.role };
    next();
  } catch (error) {
    res.status(401).json({ success: false, message: "Invalid token" });
  }
};
