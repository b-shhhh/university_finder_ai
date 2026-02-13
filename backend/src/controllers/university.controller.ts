import { Request, Response } from "express";
import {
  getAllUniversitiesService,
  getCountriesService,
  getUniversitiesService,
  getUniversityDetailService,
  getCoursesService
} from "../services/university.service";

export const getAllUniversities = async (_req: Request, res: Response) => {
  try {
    const universities = await getAllUniversitiesService();
    res.status(200).json({ success: true, data: universities });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all countries
export const getCountries = async (_req: Request, res: Response) => {
  try {
    const countries = await getCountriesService();
    res.status(200).json({ success: true, data: countries });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get universities by country
export const getUniversities = async (req: Request, res: Response) => {
  try {
    const country = Array.isArray(req.params.country) ? req.params.country[0] : req.params.country;
    const universities = await getUniversitiesService(country);
    res.status(200).json({ success: true, data: universities });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get university details by ID
export const getUniversityDetail = async (req: Request, res: Response) => {
  try {
    const universityId = Array.isArray(req.params.universityId) ? req.params.universityId[0] : req.params.universityId;
    const uni = await getUniversityDetailService(universityId);
    res.status(200).json({ success: true, data: uni });
  } catch (error: any) {
    res.status(404).json({ success: false, message: error.message });
  }
};

// Get all courses
export const getCourses = async (_req: Request, res: Response) => {
  try {
    const courses = await getCoursesService();
    res.status(200).json({ success: true, data: courses });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get courses by course name
export const getCoursesByCountry = async (req: Request, res: Response) => {
  try {
    const course = Array.isArray(req.params.course) ? req.params.course[0] : req.params.course;
    const data = await getCoursesService(course);
    res.status(200).json({ success: true, data });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
