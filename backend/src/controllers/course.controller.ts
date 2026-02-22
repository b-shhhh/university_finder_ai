import { Request, Response } from "express";
import { getAllCourses, getCoursesByCountry, getCourseById, getCountriesForCourse } from "../services/course.service";

// List all courses
export const listCourses = async (req: Request, res: Response) => {
  try {
    const courses = await getAllCourses();
    res.status(200).json({ success: true, data: courses });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// List courses available in a country
export const coursesByCountry = async (req: Request, res: Response) => {
  try {
    const country = Array.isArray(req.params.country) ? req.params.country[0] : req.params.country;
    const courses = await getCoursesByCountry(country);
    res.status(200).json({ success: true, data: courses });
  } catch (error: any) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Get course details by ID
export const courseDetails = async (req: Request, res: Response) => {
  try {
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const course = await getCourseById(id);
    res.status(200).json({ success: true, data: course });
  } catch (error: any) {
    res.status(404).json({ success: false, message: error.message });
  }
};

// List countries that offer a course
export const countriesByCourse = async (req: Request, res: Response) => {
  try {
    const course = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const countries = await getCountriesForCourse(course);
    res.status(200).json({ success: true, data: countries });
  } catch (error: any) {
    res.status(404).json({ success: false, message: error.message });
  }
};
