import { Router } from "express";
import {
  getAllUniversities,
  getCountries,
  getUniversities,
  getUniversityDetail,
  getCourses,
  getCoursesByCountry
} from "../controllers/university.controller";

const router = Router();

router.get("/", getAllUniversities);

// Countries
router.get("/countries", getCountries);

// Universities by country
router.get("/country/:country", getUniversities);

// Courses
router.get("/courses", getCourses);
router.get("/courses/:course", getCoursesByCountry);

// University details
router.get("/:universityId", getUniversityDetail);


export default router;
