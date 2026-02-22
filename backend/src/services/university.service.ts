import { University } from "../models/university.model";
import mongoose from "mongoose";

type UniversityApiItem = {
  id: string;
  dbId: string;
  alpha2: string;
  country: string;
  state?: string;
  city?: string;
  name: string;
  web_pages?: string;
  flag_url?: string;
  logo_url?: string;
  courses: string[];
  courseCategories?: string[];
  degreeLevels?: string[];
  ieltsMin?: number | null;
  satRequired?: boolean;
  satMin?: number | null;
  description?: string;
};

const normalize = (value: string) => value.trim().toLowerCase();

const mapUniversity = (uni: any): UniversityApiItem => ({
  id: String(uni.sourceId || uni._id),
  dbId: String(uni._id),
  alpha2: String(uni.alpha2 || "").toUpperCase(),
  country: String(uni.country || ""),
  state: uni.state || undefined,
  city: uni.city || undefined,
  name: String(uni.name || ""),
  web_pages: uni.web_pages || undefined,
  flag_url: uni.flag_url || undefined,
  logo_url: uni.logo_url || undefined,
  courses: Array.isArray(uni.courses) ? uni.courses.map((course: unknown) => String(course)).filter(Boolean) : [],
  courseCategories: Array.isArray(uni.courseCategories)
    ? uni.courseCategories.map((item: unknown) => String(item)).filter(Boolean)
    : undefined,
  degreeLevels: Array.isArray(uni.degreeLevels)
    ? uni.degreeLevels.map((item: unknown) => String(item)).filter(Boolean)
    : undefined,
  ieltsMin: typeof uni.ieltsMin === "number" ? uni.ieltsMin : null,
  satRequired: typeof uni.satRequired === "boolean" ? uni.satRequired : undefined,
  satMin: typeof uni.satMin === "number" ? uni.satMin : null,
  description: uni.description || undefined,
});

export const getAllUniversitiesService = async () => {
  const universities = await University.find().sort({ name: 1 }).lean();
  return universities.map(mapUniversity);
};

/**
 * Get all distinct countries
 */
export const getCountriesService = async (): Promise<string[]> => {
  const countries = await University.distinct("country");
  return countries.map((country) => String(country)).filter(Boolean).sort((a, b) => a.localeCompare(b));
};

/**
 * Get universities by country
 */
export const getUniversitiesService = async (country: string) => {
  const query = country.trim();
  const alpha2 = query.toUpperCase();
  const regex = new RegExp(`^${query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i");
  const universities = await University.find({
    $or: [{ country: regex }, { alpha2 }],
  }).sort({ name: 1 }).lean();
  return universities.map(mapUniversity);
};

/**
 * Get university details by ID
 */
export const getUniversityDetailService = async (universityId: string) => {
  const detailLookup: Array<Record<string, unknown>> = [{ sourceId: universityId }];
  if (mongoose.Types.ObjectId.isValid(universityId)) {
    detailLookup.push({ _id: universityId });
  }
  const uni = await University.findOne({ $or: detailLookup }).lean();
  if (!uni) throw new Error("University not found");
  return mapUniversity(uni);
};

/**
 * Get multiple university details by comma-separated ids
 */
export const getUniversitiesByIdsService = async (ids: string[]) => {
  const lookups: Array<Record<string, unknown>> = [];
  const sourceIds = ids.filter((id) => !mongoose.Types.ObjectId.isValid(id));
  const objectIds = ids.filter((id) => mongoose.Types.ObjectId.isValid(id));

  if (sourceIds.length) lookups.push({ sourceId: { $in: sourceIds } });
  if (objectIds.length) lookups.push({ _id: { $in: objectIds } });

  if (!lookups.length) return [];
  const universities = await University.find({ $or: lookups }).lean();
  return universities.map(mapUniversity);
};

/**
 * Get all courses, or filter by course name
 */
export const getCoursesService = async (courseName?: string) => {
  const universities = await University.find({}, { courses: 1 }).lean();
  const allCourses = Array.from(
    new Set(
      universities.flatMap((uni) =>
        Array.isArray(uni.courses) ? uni.courses.map((course: unknown) => String(course).trim()).filter(Boolean) : []
      )
    )
  ).sort((a, b) => a.localeCompare(b));

  if (courseName) {
    const course = allCourses.find((item) => normalize(item) === normalize(courseName));
    if (!course) throw new Error("Course not found");
    return course;
  }
  return allCourses;
};
