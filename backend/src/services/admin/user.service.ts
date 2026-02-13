import bcrypt from "bcrypt";
import { User } from "../../models/user.model";
import { buildSearchRegex, toPagination } from "../../utils/helpers";

export const listAdminUsersService = async (query: {
  page?: string;
  limit?: string;
  search?: string;
  role?: string;
}) => {
  const { page, limit, skip } = toPagination(query.page, query.limit);
  const filter: Record<string, unknown> = {};

  if (query.role?.trim()) {
    filter.role = query.role.trim();
  }

  const searchRegex = buildSearchRegex(query.search);
  if (searchRegex) {
    filter.$or = [{ fullName: searchRegex }, { email: searchRegex }, { phone: searchRegex }];
  }

  const [items, total] = await Promise.all([
    User.find(filter)
      .select("-password -resetPasswordToken -resetPasswordExpires")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    User.countDocuments(filter),
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

export const getAdminUserByIdService = async (id: string) => {
  const user = await User.findById(id).select("-password -resetPasswordToken -resetPasswordExpires");
  if (!user) throw new Error("User not found");
  return user;
};

export const updateAdminUserByIdService = async (
  id: string,
  payload: Partial<{ fullName: string; email: string; phone: string; role: "user" | "admin"; country: string; bio: string; password: string }>,
) => {
  const updates: Record<string, unknown> = {};
  if (typeof payload.fullName === "string") updates.fullName = payload.fullName.trim();
  if (typeof payload.email === "string") updates.email = payload.email.trim().toLowerCase();
  if (typeof payload.phone === "string") updates.phone = payload.phone.trim();
  if (typeof payload.country === "string") updates.country = payload.country.trim();
  if (typeof payload.bio === "string") updates.bio = payload.bio.trim();
  if (payload.role === "user" || payload.role === "admin") updates.role = payload.role;

  if (typeof payload.password === "string" && payload.password.trim()) {
    updates.password = await bcrypt.hash(payload.password.trim(), 10);
  }

  const user = await User.findByIdAndUpdate(id, updates, { new: true }).select(
    "-password -resetPasswordToken -resetPasswordExpires",
  );
  if (!user) throw new Error("User not found");
  return user;
};

export const deleteAdminUserByIdService = async (id: string) => {
  const deleted = await User.findByIdAndDelete(id);
  if (!deleted) throw new Error("User not found");
  return deleted;
};

