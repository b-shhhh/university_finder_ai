import { Router } from "express";
import {
  register,
  login,
  whoAmI,
  updateProfile,
  changePassword,
  requestPasswordReset,
  resetPassword
} from "../controllers/auth.controller";
import { removeAccount } from "../controllers/user.controller";
import { authMiddleware } from "../middlewares/auth.middleware";
import { upload } from "../middlewares/upload.middleware";

const router = Router();

router.post("/register", register);
router.post("/login", login);

router.get("/whoami", authMiddleware, whoAmI);
router.get("/me", authMiddleware, whoAmI);
router.put(
  "/update-profile",
  authMiddleware,
  upload.fields([
    { name: "profilePic", maxCount: 1 },
    { name: "profileImage", maxCount: 1 },
  ]),
  updateProfile,
);
router.put("/change-password", authMiddleware, changePassword);
router.delete("/delete-account", authMiddleware, removeAccount);

router.post("/request-password-reset", requestPasswordReset);
router.post("/reset-password/:token", resetPassword);

export default router;
