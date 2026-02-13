import { Router } from "express";
import { adminLogin, adminProfile } from "../../controllers/admin/admin.controller";
import { authMiddleware } from "../../middlewares/auth.middleware";

const router = Router();

router.post("/login", adminLogin);
router.get("/profile", authMiddleware, adminProfile);

export default router;

