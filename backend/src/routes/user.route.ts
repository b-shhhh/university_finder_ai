import { Router } from "express";
import { authMiddleware } from "../middlewares/auth.middleware";
import { getProfile, editProfile, changePassword, removeAccount } from "../controllers/user.controller";

const router = Router();

router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, editProfile);
router.put("/change-password", authMiddleware, changePassword);
router.delete("/profile", authMiddleware, removeAccount);

export default router;
