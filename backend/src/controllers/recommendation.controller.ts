import { Request, Response } from "express";
import { getRecommendationsService } from "../services/recommendation.service";

export const getRecommendations = async (_req: Request, res: Response) => {
  try {
    const data = await getRecommendationsService();
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
