import { Response } from "express";
import { AuthRequest } from "../../types/user.type";
import {
  deleteAdminUserByIdService,
  getAdminUserByIdService,
  listAdminUsersService,
  updateAdminUserByIdService,
} from "../../services/admin/user.service";

const isAdmin = (req: AuthRequest) => req.user?.role === "admin";
const getParamId = (req: AuthRequest) => (Array.isArray(req.params.id) ? req.params.id[0] : req.params.id);

export const adminListUsers = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });

    const data = await listAdminUsersService({
      page: String(req.query.page || ""),
      limit: String(req.query.limit || ""),
      search: String(req.query.search || ""),
      role: String(req.query.role || ""),
    });
    res.status(200).json({ success: true, data: data.items, pagination: data.pagination });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminGetUser = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    const data = await getAdminUserByIdService(id);
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(404).json({ success: false, message: error.message });
  }
};

export const adminUpdateUser = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    const data = await updateAdminUserByIdService(id, req.body || {});
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminDeleteUser = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    await deleteAdminUserByIdService(id);
    res.status(200).json({ success: true, message: "User deleted successfully" });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
