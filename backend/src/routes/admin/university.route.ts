import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import {
  adminCreateUniversity,
  adminDeleteUniversity,
  adminGetUniversity,
  adminListUniversities,
  adminUpdateUniversity,
} from "../../controllers/admin/university.controller";

const router = Router();

router.get("/", authMiddleware, adminListUniversities);
router.get("/:id", authMiddleware, adminGetUniversity);
router.post("/", authMiddleware, adminCreateUniversity);
router.put("/:id", authMiddleware, adminUpdateUniversity);
router.delete("/:id", authMiddleware, adminDeleteUniversity);

export default router;

