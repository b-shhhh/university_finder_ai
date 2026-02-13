import { Router } from "express";
import { getRecommendations } from "../controllers/recommendation.controller";

const router = Router();

router.get("/", getRecommendations);

export default router;
