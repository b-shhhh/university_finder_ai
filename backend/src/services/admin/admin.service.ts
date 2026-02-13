import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../../config";
import { User } from "../../models/user.model";

export const adminLoginService = async (emailInput: string, password: string) => {
  const email = emailInput.trim().toLowerCase();
  const user = await User.findOne({ email });
  if (!user) {
    throw new Error("Invalid email or password");
  }

  if (user.role !== "admin" && email !== "admin@gmail.com") {
    throw new Error("Admin access required");
  }

  const valid = await bcrypt.compare(password, user.password);
  if (!valid) {
    throw new Error("Invalid email or password");
  }

  const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: "7d" });
  return {
    token,
    user: {
      id: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      phone: user.phone,
      country: user.country,
      bio: user.bio,
      profilePic: user.profilePic,
    },
  };
};

export const adminProfileService = async (adminId: string) => {
  const admin = await User.findById(adminId).select("-password -resetPasswordToken -resetPasswordExpires");
  if (!admin) {
    throw new Error("Admin not found");
  }
  if (admin.role !== "admin") {
    throw new Error("Admin access required");
  }
  return admin;
};
