import { z } from "zod";

const registerBaseSchema = z.object({
  // Supports frontend payload (`fullName`) and legacy payload (`username`)
  fullName: z.string().min(2, "Full name is required").optional(),
  email: z
    .string()
    .refine((value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value), "Invalid email"),
  countryCode: z
    .string()
    .refine((value) => /^\+\d{1,3}$/.test(value), "Invalid country code")
    .optional(),
  phone: z.string().min(7, "Phone number too short"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  confirmPassword: z.string().min(6, "Confirm password is required").optional()
});

// Register input validation
export const registerSchema = registerBaseSchema
  .refine((data) => Boolean(data.fullName), {
    message: "Provide fullName",
    path: ["fullName"]
  })
  .refine((data) => !data.confirmPassword || data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"]
  });

export type RegisterInput = z.infer<typeof registerSchema>;

// Login input validation
export const loginSchema = z.object({
  email: z
    .string()
    .refine((value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value), "Invalid email"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  role: z.enum(["user", "admin"]).optional()
});

export type LoginInput = z.infer<typeof loginSchema>;
