// src/repositories/university.repository.ts
import { University, IUniversity } from "../models/university.model";
import mongoose from "mongoose";

export class UniversityRepository {
    async createUniversity(data: Partial<IUniversity>): Promise<IUniversity> {
        const uni = new University(data);
        return uni.save();
    }

    async findAll(): Promise<IUniversity[]> {
        return University.find();
    }

    async findById(id: string): Promise<IUniversity | null> {
        if (!mongoose.Types.ObjectId.isValid(id)) return null;
        return University.findById(id);
    }

    async findByCountry(country: string): Promise<IUniversity[]> {
        return University.find({ country });
    }

    async findByCourse(course: string): Promise<IUniversity[]> {
        return University.find({ courses: course });
    }
}
