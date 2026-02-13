import { Router } from "express";
import { authMiddleware } from "../../middlewares/auth.middleware";
import { adminDeleteUser, adminGetUser, adminListUsers, adminUpdateUser } from "../../controllers/admin/user.controller";

const router = Router();

router.get("/", authMiddleware, adminListUsers);
router.get("/:id", authMiddleware, adminGetUser);
router.put("/:id", authMiddleware, adminUpdateUser);
router.delete("/:id", authMiddleware, adminDeleteUser);

export default router;

