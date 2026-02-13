import mongoose, { Schema, Document } from "mongoose";

export interface ICourse extends Document {
  name: string;
  countries: string[]; // List of countries offering this course
  description?: string;
}

const courseSchema = new Schema<ICourse>({
  name: { type: String, required: true },
  countries: [{ type: String, required: true }],
  description: { type: String }
}, { timestamps: true });

export const Course = mongoose.model<ICourse>("Course", courseSchema);
