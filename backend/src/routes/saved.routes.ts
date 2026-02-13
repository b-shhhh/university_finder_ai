import { Router } from "express";
import { authMiddleware } from "../middlewares/auth.middleware";
import {
  saveUniversity,
  getSavedUniversities,
  removeSavedUniversity
} from "../controllers/saved.controller";

const router = Router();

router.post("/", authMiddleware, saveUniversity);
router.get("/", authMiddleware, getSavedUniversities);
router.delete("/:universityId", authMiddleware, removeSavedUniversity);

export default router;
