// src/app.ts
import express, { Application } from "express";
import dotenv from "dotenv";
import cors from "cors";
import path from "path";
import mongoose from "mongoose";

import { ALLOWED_ORIGINS } from "./config";
import { connectDatabase } from "./database/mongodb";

// Routes
import authRoutes from "./routes/auth.route";
import userRoutes from "./routes/user.route";
import universityRoutes from "./routes/university.route";
import courseRoutes from "./routes/course.route";
import savedRoutes from "./routes/saved.routes";
import recommendationRoutes from "./routes/recommendation.route";
import adminRoutes from "./routes/admin/admin.route";
import adminUniversityRoutes from "./routes/admin/university.route";
import adminUserRoutes from "./routes/admin/user.route";

// Middlewares
import { errorMiddleware } from "./middlewares/error.middleware";
import { rateLimitMiddleware, securityHeadersMiddleware } from "./middlewares/security.middleware";

dotenv.config();

const app: Application = express();
app.set("trust proxy", 1);
const uploadDir = path.resolve(process.cwd(), "uploads");

// CORS options
const corsOptions = {
  origin: ALLOWED_ORIGINS,
  credentials: true
};
app.use(cors(corsOptions));
app.use(securityHeadersMiddleware);
app.use(rateLimitMiddleware);

// Serve static files (uploads)
app.use("/uploads", express.static(uploadDir));

// Body parser
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

// Connect to MongoDB
connectDatabase()
  .then(() => console.log("MongoDB connected"))
  .catch((err) => {
    console.error("MongoDB connection failed:", err);
    process.exit(1);
  });

app.get("/health", (_req, res) => {
  res.status(200).json({ success: true, status: "ok", uptime: process.uptime() });
});

app.get("/ready", (_req, res) => {
  const ready = mongoose.connection.readyState === 1;
  if (!ready) {
    return res.status(503).json({ success: false, status: "not-ready" });
  }
  return res.status(200).json({ success: true, status: "ready" });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/universities", universityRoutes);
app.use("/api/courses", courseRoutes);
app.use("/api/saved-universities", savedRoutes);
app.use("/api/recommendations", recommendationRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/admin/universities", adminUniversityRoutes);
app.use("/api/admin/users", adminUserRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ message: "Route Not Found" });
});

// Error middleware
app.use(errorMiddleware);

export default app;
