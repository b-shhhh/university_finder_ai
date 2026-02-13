import { Response, Request } from "express";
import {
  saveUniversityService,
  getSavedUniversitiesService,
  removeSavedUniversityService
} from "../services/user.service";
import { RequestUser } from "../types/user.type";

// Extend Request to include user
interface AuthRequest extends Request {
  user?: RequestUser;
}

// Save a university
export const saveUniversity = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    // Normalize universityId in case it's an array
    const universityId = Array.isArray(req.body.universityId)
      ? req.body.universityId[0]
      : req.body.universityId;
    if (!universityId) {
      return res.status(400).json({ success: false, message: "universityId is required" });
    }

    const user = await saveUniversityService(userId, universityId);

    res.status(200).json({ success: true, data: user.savedUniversities });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Get saved universities
export const getSavedUniversities = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    const savedUniversities = await getSavedUniversitiesService(userId);

    res.status(200).json({ success: true, data: savedUniversities });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Remove a saved university
export const removeSavedUniversity = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    const universityId = Array.isArray(req.params.universityId)
      ? req.params.universityId[0]
      : req.params.universityId;

    const user = await removeSavedUniversityService(userId, universityId);

    res.status(200).json({ success: true, data: user.savedUniversities });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};
