import { Router } from "express";
import { listCourses, coursesByCountry, courseDetails } from "../controllers/course.controller";

const router = Router();

// Get all courses
router.get("/", listCourses);

// Get courses available in a specific country
router.get("/country/:country", coursesByCountry);

// Get course details by ID
router.get("/:id", courseDetails);

export default router;
