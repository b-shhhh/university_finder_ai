import { User, IUser } from "../models/user.model";
import mongoose from "mongoose";

export const findUserByEmail = async (email: string): Promise<IUser | null> => {
  return await User.findOne({ email });
};

export const findUserById = async (id: string | mongoose.Types.ObjectId): Promise<IUser | null> => {
  return await User.findById(id);
};

export const createUser = async (data: Partial<IUser>): Promise<IUser> => {
  const user = new User(data);
  return await user.save();
};

export const updateUser = async (id: string, data: Partial<IUser>): Promise<IUser | null> => {
  return await User.findByIdAndUpdate(id, data, { returnDocument: "after" });
};

export const deleteUser = async (id: string): Promise<IUser | null> => {
  return await User.findByIdAndDelete(id);
};
