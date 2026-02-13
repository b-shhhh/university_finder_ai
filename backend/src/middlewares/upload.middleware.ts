// src/middlewares/upload.middleware.ts
import multer, { FileFilterCallback } from "multer";
import { Request } from "express";
import fs from "fs";
import path from "path";

const uploadDir = path.resolve(process.cwd(), "uploads");

// Configure storage
const storage = multer.diskStorage({
  destination: function (_req, _file, cb) {
    fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: function (_req, file, cb) {
    const ext = path.extname(file.originalname);
    const name = file.fieldname + "-" + Date.now() + ext;
    cb(null, name);
  },
});

// Optional: filter by file type (e.g., only images)
const fileFilter = (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
  const originalName = String(file.originalname || "").trim();
  // Some clients can send an empty file part for optional file inputs.
  // Ignore it instead of failing the whole request.
  if (!originalName || file.size === 0) {
    cb(null, false);
    return;
  }

  const ext = path.extname(file.originalname || "").toLowerCase();
  const allowedExt = new Set([".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg", ".avif", ".jfif", ".heic", ".heif"]);
  const isImageMime = typeof file.mimetype === "string" && file.mimetype.startsWith("image/");
  const isImageExt = allowedExt.has(ext);

  if (isImageMime || isImageExt) {
    cb(null, true);
  } else {
    // Ignore unsupported file types instead of throwing and crashing request handling.
    cb(null, false);
  }
};

export const upload = multer({ storage, fileFilter });
