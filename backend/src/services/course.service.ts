import { University } from "../models/university.model";

const normalize = (value: string) => value.trim().toLowerCase();

const collectCourses = (rows: Array<{ courses?: unknown }>) =>
  Array.from(
    new Set(
      rows.flatMap((row) =>
        Array.isArray(row.courses) ? row.courses.map((course) => String(course).trim()).filter(Boolean) : []
      )
    )
  ).sort((a, b) => a.localeCompare(b));

// Get all courses
export const getAllCourses = async () => {
  const rows = await University.find({}, { courses: 1 }).lean();
  return collectCourses(rows);
};

// Get courses available in a specific country
export const getCoursesByCountry = async (country: string) => {
  const query = country.trim();
  const alpha2 = query.toUpperCase();
  const regex = new RegExp(`^${query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i");
  const rows = await University.find({ $or: [{ country: regex }, { alpha2 }] }, { courses: 1 }).lean();
  return collectCourses(rows);
};

// Get course details by ID
export const getCourseById = async (id: string) => {
  const rows = await University.find({}, { courses: 1 }).lean();
  const courses = collectCourses(rows);
  const course = courses.find((item) => normalize(item) === normalize(id));
  if (!course) throw new Error("Course not found");
  return course;
};

// Get countries offering a specific course
export const getCountriesForCourse = async (course: string) => {
  const needle = normalize(course);
  const rows = await University.find({}).select("country courses").lean();
  const countries = Array.from(
    new Set(
      rows
        .filter((row) => Array.isArray(row.courses) && row.courses.some((c) => normalize(c) === needle))
        .map((row) => String(row.country || "").trim())
        .filter(Boolean)
    )
  ).sort((a, b) => a.localeCompare(b));
  if (!countries.length) throw new Error("Course not found in any country");
  return countries;
};
