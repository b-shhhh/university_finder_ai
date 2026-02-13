import mongoose, { Schema, Document } from "mongoose";

export interface IUniversity extends Document {
  sourceId?: string;
  alpha2?: string;
  name: string;
  country: string;
  web_pages?: string;
  flag_url?: string;
  logo_url?: string;
  courses: string[]; // List of course names
  description?: string;
}

const universitySchema = new Schema<IUniversity>({
  sourceId: { type: String, unique: true, sparse: true, index: true },
  alpha2: { type: String },
  name: { type: String, required: true },
  country: { type: String, required: true },
  web_pages: { type: String },
  flag_url: { type: String },
  logo_url: { type: String },
  courses: [{ type: String }],
  description: { type: String },
}, { timestamps: true });

export const University = mongoose.model<IUniversity>("University", universitySchema);
