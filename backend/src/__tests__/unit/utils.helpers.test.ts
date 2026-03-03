import { buildSearchRegex, normalizeText, readCsvFile, toPagination } from "../../utils/helpers";

jest.mock("fs/promises", () => ({
  readFile: jest.fn(async () => "id,name\n1,Alice\n2,Bob")
}));

describe("utils/helpers", () => {
  test("normalizeText trims and lowercases", () => {
    expect(normalizeText("  Hello  ")).toBe("hello");
  });

  test("toPagination clamps values", () => {
    expect(toPagination(-1, 500)).toEqual({ page: 1, limit: 100, skip: 0 });
  });

  test("toPagination computes skip", () => {
    expect(toPagination(3, 10).skip).toBe(20);
  });

  test("toPagination defaults when undefined", () => {
    expect(toPagination(undefined, undefined)).toEqual({ page: 1, limit: 10, skip: 0 });
  });

  test("buildSearchRegex escapes special chars", () => {
    const regex = buildSearchRegex("uni.*");
    expect(regex!.test("UNI.*")).toBe(true);
  });

  test("buildSearchRegex returns null for blank", () => {
    expect(buildSearchRegex("   ")).toBeNull();
  });

  test("buildSearchRegex matches case-insensitive", () => {
    const regex = buildSearchRegex("Harvard");
    expect(regex!.test("harvard university")).toBe(true);
  });

  test("buildSearchRegex escapes regex tokens", () => {
    const regex = buildSearchRegex("c++");
    expect(regex!.source).toContain("\\+\\+");
  });

  test("readCsvFile returns file content", async () => {
    const csv = await readCsvFile("file.csv");
    expect(csv).toContain("Alice");
  });

  test("toPagination caps limit at 100", () => {
    expect(toPagination(1, 5000).limit).toBe(100);
  });
});
