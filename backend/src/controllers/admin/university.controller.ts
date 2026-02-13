import { Response } from "express";
import { AuthRequest } from "../../types/user.type";
import {
  createAdminUniversityService,
  deleteAdminUniversityService,
  getAdminUniversityByIdService,
  listAdminUniversitiesService,
  updateAdminUniversityService,
} from "../../services/admin/university.service";

const isAdmin = (req: AuthRequest) => req.user?.role === "admin";
const getParamId = (req: AuthRequest) => (Array.isArray(req.params.id) ? req.params.id[0] : req.params.id);

export const adminListUniversities = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });

    const data = await listAdminUniversitiesService({
      page: String(req.query.page || ""),
      limit: String(req.query.limit || ""),
      search: String(req.query.search || ""),
      country: String(req.query.country || ""),
    });

    res.status(200).json({ success: true, data: data.items, pagination: data.pagination });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminGetUniversity = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    const data = await getAdminUniversityByIdService(id);
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(404).json({ success: false, message: error.message });
  }
};

export const adminCreateUniversity = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });

    const { name, country, courses, description } = req.body || {};
    if (!name || !country) {
      return res.status(400).json({ success: false, message: "name and country are required" });
    }

    const data = await createAdminUniversityService({
      name: String(name),
      country: String(country),
      courses: courses as string[] | string | undefined,
      description: typeof description === "string" ? description : undefined,
    });
    res.status(201).json({ success: true, data });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminUpdateUniversity = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    const data = await updateAdminUniversityService(id, req.body || {});
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

export const adminDeleteUniversity = async (req: AuthRequest, res: Response) => {
  try {
    if (!isAdmin(req)) return res.status(403).json({ success: false, message: "Admin access required" });
    const id = getParamId(req);
    await deleteAdminUniversityService(id);
    res.status(200).json({ success: true, message: "University deleted successfully" });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
