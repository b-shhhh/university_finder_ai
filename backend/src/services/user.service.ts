import { IUser, User } from "../models/user.model";
import bcrypt from "bcrypt";
import { University } from "../models/university.model";
import mongoose from "mongoose";
import {
  findUserById,
  updateUser,
  deleteUser
} from "../repositories/user.repository";

// -----------------------------
// Profile Services
// -----------------------------

// Get user profile
export const getUserProfile = async (userId: string): Promise<IUser | null> => {
  return await findUserById(userId);
};

// Update user profile
export const updateProfile = async (userId: string, data: Partial<IUser>): Promise<IUser | null> => {
  if (data.password) {
    data.password = await bcrypt.hash(data.password, 10);
  }
  return await updateUser(userId, data);
};

// Delete user account
export const deleteAccount = async (userId: string): Promise<IUser | null> => {
  return await deleteUser(userId);
};

// -----------------------------
// Saved Universities Services
// -----------------------------

// Save a university for a user
export const saveUniversityService = async (userId: string, universityId: string): Promise<IUser> => {
  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");
  if (!universityId) throw new Error("University ID is required");

  const saveLookup: Array<Record<string, unknown>> = [{ sourceId: universityId }];
  if (mongoose.Types.ObjectId.isValid(universityId)) {
    saveLookup.push({ _id: universityId });
  }

  const matchedUniversity = await University.findOne({ $or: saveLookup }).select("_id sourceId");

  const canonicalId = matchedUniversity ? String(matchedUniversity.sourceId || matchedUniversity._id) : universityId;
  const aliases = matchedUniversity
    ? Array.from(new Set([String(matchedUniversity._id), String(matchedUniversity.sourceId || ""), canonicalId])).filter(Boolean)
    : [canonicalId];

  user.savedUniversities = user.savedUniversities.map((id) => String(id));
  user.savedUniversities = user.savedUniversities.filter((savedId) => !aliases.includes(savedId));
  if (!user.savedUniversities.includes(canonicalId)) {
    user.savedUniversities.push(canonicalId);
    await user.save({ validateBeforeSave: false });
  }

  return user;
};

// Get saved universities for a user
export const getSavedUniversitiesService = async (userId: string) => {
  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");

  const normalized = user.savedUniversities.map((id) => String(id)).filter(Boolean);
  const sourceIds = normalized.filter((id) => !mongoose.Types.ObjectId.isValid(id));
  const objectIds = normalized.filter((id) => mongoose.Types.ObjectId.isValid(id));
  const lookup: Array<Record<string, unknown>> = [];
  if (sourceIds.length) {
    lookup.push({ sourceId: { $in: sourceIds } });
  }
  if (objectIds.length) {
    lookup.push({ _id: { $in: objectIds } });
  }

  const universities = lookup.length
    ? await University.find({ $or: lookup }).select("_id sourceId")
    : [];

  const bySourceId = new Map<string, string>();
  const byDbId = new Map<string, string>();
  for (const uni of universities) {
    const sourceId = String(uni.sourceId || uni._id);
    bySourceId.set(sourceId, sourceId);
    byDbId.set(String(uni._id), sourceId);
  }

  return Array.from(
    new Set(
      normalized.map((id) => bySourceId.get(id) || byDbId.get(id) || id)
    )
  );
};

// Remove a saved university
export const removeSavedUniversityService = async (userId: string, universityId: string) => {
  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");

  const removeLookup: Array<Record<string, unknown>> = [{ sourceId: universityId }];
  if (mongoose.Types.ObjectId.isValid(universityId)) {
    removeLookup.push({ _id: universityId });
  }

  const matchedUniversity = await University.findOne({ $or: removeLookup }).select("_id sourceId");

  const aliases = matchedUniversity
    ? Array.from(new Set([String(matchedUniversity._id), String(matchedUniversity.sourceId || ""), universityId])).filter(Boolean)
    : [universityId];

  user.savedUniversities = user.savedUniversities
    .map((id) => String(id))
    .filter((id) => !aliases.includes(id));

  await user.save({ validateBeforeSave: false });
  return user;
};
