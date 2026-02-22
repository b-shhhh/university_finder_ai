import { Router } from "express";
import { listCourses, coursesByCountry, courseDetails, countriesByCourse } from "../controllers/course.controller";

const router = Router();

// Get all courses
router.get("/", listCourses);

// Get courses available in a specific country
router.get("/country/:country", coursesByCountry);

// Get countries that offer a course (place before :id)
router.get("/:id/countries", countriesByCourse);

// Get course details by ID
router.get("/:id", courseDetails);

export default router;
