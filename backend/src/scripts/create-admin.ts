import bcrypt from "bcrypt";
import mongoose from "mongoose";
import { connectDatabase } from "../database/mongodb";
import { User } from "../models/user.model";

const ADMIN_EMAIL = (process.env.ADMIN_EMAIL || "admin@gmail.com").trim().toLowerCase();
const ADMIN_PASSWORD = (process.env.ADMIN_PASSWORD || "admin123456").trim();
const ADMIN_FULL_NAME = (process.env.ADMIN_FULL_NAME || "System Admin").trim();
const ADMIN_PHONE = (process.env.ADMIN_PHONE || "9800000000").trim();

async function createOrUpdateAdmin() {
  await connectDatabase();

  const existing = await User.findOne({ email: ADMIN_EMAIL });
  const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);

  if (existing) {
    existing.fullName = existing.fullName || ADMIN_FULL_NAME;
    existing.phone = existing.phone || ADMIN_PHONE;
    existing.role = "admin";
    existing.password = hashedPassword;
    await existing.save();
    console.log(`Updated admin user: ${ADMIN_EMAIL}`);
  } else {
    await User.create({
      fullName: ADMIN_FULL_NAME,
      email: ADMIN_EMAIL,
      phone: ADMIN_PHONE,
      password: hashedPassword,
      role: "admin",
    });
    console.log(`Created admin user: ${ADMIN_EMAIL}`);
  }
}

createOrUpdateAdmin()
  .catch((error) => {
    console.error("Failed to create/update admin user:", error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.connection.close();
  });
