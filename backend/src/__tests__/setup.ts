import { connectDatabase } from "../database/mongodb";
import mongoose from "mongoose";

process.env.DOTENV_DISABLE_LOGS = "true";
const logSpy = jest.spyOn(console, "log").mockImplementation(() => {});
const errorSpy = jest.spyOn(console, "error").mockImplementation(() => {});

beforeAll(async () => {
  if (process.env.SKIP_DB === "true") return;
  await connectDatabase();
});

afterAll(async () => {
  await mongoose.connection.close();
  logSpy.mockRestore();
  errorSpy.mockRestore();
});


