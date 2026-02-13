// src/models/country.model.ts
import mongoose, { Schema, Document, Model } from "mongoose";

export interface ICountry extends Document {
    name: string;
    flagUrl?: string;
}

const countrySchema = new Schema<ICountry>(
    {
        name: { type: String, required: true },
        flagUrl: { type: String },
    },
    { timestamps: true }
);

export const Country: Model<ICountry> = mongoose.model<ICountry>("Country", countrySchema);
