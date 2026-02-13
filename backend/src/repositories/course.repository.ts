// src/repositories/course.repository.ts
import { Course, ICourse } from "../models/course.model";
import mongoose from "mongoose";

export class CourseRepository {
    async createCourse(data: Partial<ICourse>): Promise<ICourse> {
        const course = new Course(data);
        return course.save();
    }

    async findAll(): Promise<ICourse[]> {
        return Course.find().populate("universities");
    }

    async findByName(name: string): Promise<ICourse | null> {
        return Course.findOne({ name }).populate("universities");
    }
}
