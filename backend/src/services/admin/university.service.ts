import { University, IUniversity } from "../../models/university.model";
import { buildSearchRegex, toPagination } from "../../utils/helpers";

export const listAdminUniversitiesService = async (query: {
  page?: string;
  limit?: string;
  search?: string;
  country?: string;
}) => {
  const { page, limit, skip } = toPagination(query.page, query.limit);
  const filter: Record<string, unknown> = {};

  if (query.country?.trim()) {
    filter.country = query.country.trim();
  }

  const searchRegex = buildSearchRegex(query.search);
  if (searchRegex) {
    filter.$or = [
      { name: searchRegex },
      { country: searchRegex },
      { state: searchRegex },
      { city: searchRegex },
      { courses: searchRegex },
      { courseCategories: searchRegex },
    ];
  }

  const [items, total] = await Promise.all([
    University.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    University.countDocuments(filter),
  ]);

  return {
    items,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.max(1, Math.ceil(total / limit)),
    },
  };
};

export const getAdminUniversityByIdService = async (id: string) => {
  const item = await University.findById(id);
  if (!item) throw new Error("University not found");
  return item;
};

export const createAdminUniversityService = async (payload: {
  name: string;
  country: string;
  courses?: string[] | string;
  description?: string;
}) => {
  const courses = Array.isArray(payload.courses)
    ? payload.courses
    : typeof payload.courses === "string"
    ? payload.courses.split(",").map((item) => item.trim()).filter(Boolean)
    : [];

  const item = await University.create({
    name: payload.name.trim(),
    country: payload.country.trim(),
    courses,
    description: payload.description?.trim() || undefined,
  });
  return item;
};

export const updateAdminUniversityService = async (
  id: string,
  payload: Partial<{ name: string; country: string; courses: string[] | string; description: string }>,
) => {
  const updates: Record<string, unknown> = {};
  if (typeof payload.name === "string") updates.name = payload.name.trim();
  if (typeof payload.country === "string") updates.country = payload.country.trim();
  if (typeof payload.description === "string") updates.description = payload.description.trim();
  if (Array.isArray(payload.courses)) updates.courses = payload.courses.map((item) => item.trim()).filter(Boolean);
  if (typeof payload.courses === "string") {
    updates.courses = payload.courses.split(",").map((item) => item.trim()).filter(Boolean);
  }

  const item = await University.findByIdAndUpdate(id, updates, { new: true });
  if (!item) throw new Error("University not found");
  return item;
};

export const deleteAdminUniversityService = async (id: string) => {
  const deleted = await University.findByIdAndDelete(id);
  if (!deleted) throw new Error("University not found");
  return deleted;
};
