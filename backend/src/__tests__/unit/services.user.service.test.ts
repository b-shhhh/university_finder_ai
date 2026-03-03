import bcrypt from "bcrypt";
import {
  getUserProfile,
  updateProfile,
  deleteAccount,
  saveUniversityService,
  getSavedUniversitiesService,
  removeSavedUniversityService
} from "../../services/user.service";

jest.mock("../../repositories/user.repository", () => ({
  findUserById: jest.fn(),
  updateUser: jest.fn(),
  deleteUser: jest.fn()
}));

jest.mock("../../models/user.model", () => ({
  User: {
    findById: jest.fn(),
    findByIdAndUpdate: jest.fn()
  }
}));

jest.mock("../../models/university.model", () => {
  const chainableSelect = (result: any) => ({
    select: jest.fn().mockResolvedValue(result)
  });
  return {
    University: {
      findOne: jest.fn(() => chainableSelect(null)),
      find: jest.fn(() => chainableSelect([]))
    }
  };
});

jest.mock("mongoose", () => ({
  Types: {
    ObjectId: {
      isValid: jest.fn(() => false)
    }
  }
}));

jest.mock("bcrypt", () => ({
  hash: jest.fn(async (v: string) => `hashed-${v}`)
}));

const { findUserById, updateUser, deleteUser } = require("../../repositories/user.repository");
const { User } = require("../../models/user.model");
const { University } = require("../../models/university.model");

describe("services/user.service", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test("getUserProfile delegates to repository", async () => {
    findUserById.mockResolvedValue({ id: "1" });
    const user = (await getUserProfile("1")) as any;
    expect(user.id).toBe("1");
  });

  test("updateProfile hashes password when provided", async () => {
    updateUser.mockResolvedValue({ id: "1", password: "hashed-new" });
    const user = (await updateProfile("1", { password: "new" } as any)) as any;
    expect(bcrypt.hash).toHaveBeenCalledWith("new", 10);
    expect(user.password).toBe("hashed-new");
  });

  test("deleteAccount calls repository", async () => {
    deleteUser.mockResolvedValue({ id: "gone" });
    const result = (await deleteAccount("1")) as any;
    expect(result.id).toBe("gone");
  });

  test("saveUniversityService throws when user missing", async () => {
    User.findById.mockResolvedValue(null);
    await expect(saveUniversityService("u1", "x")).rejects.toThrow(/user not found/i);
  });

  test("saveUniversityService saves canonical id", async () => {
    const save = jest.fn();
    User.findById.mockResolvedValue({ savedUniversities: [], save });
    University.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({ sourceId: "src", _id: "id" })
    });
    await saveUniversityService("u1", "src");
    expect(save).toHaveBeenCalled();
  });

  test("getSavedUniversitiesService returns normalized list", async () => {
    User.findById.mockResolvedValue({ savedUniversities: ["one"] });
    University.find.mockReturnValue({
      select: jest.fn().mockResolvedValue([{ _id: "507f1f77bcf86cd799439011", sourceId: "one" }])
    });
    const list = await getSavedUniversitiesService("u1");
    expect(list).toContain("one");
  });

  test("removeSavedUniversityService removes aliases", async () => {
    const save = jest.fn();
    User.findById.mockResolvedValue({ savedUniversities: ["a", "b"], save });
    University.findOne.mockReturnValue({
      select: jest.fn().mockResolvedValue({ _id: "b", sourceId: "alias" })
    });
    await removeSavedUniversityService("u1", "b");
    expect(save).toHaveBeenCalled();
  });
});
