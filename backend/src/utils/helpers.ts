import fs from "fs/promises";

export const normalizeText = (value: string) => value.trim().toLowerCase();

export const toPagination = (page?: string | number, limit?: string | number) => {
  const safePage = Math.max(1, Number(page) || 1);
  const safeLimit = Math.max(1, Math.min(100, Number(limit) || 10));
  const skip = (safePage - 1) * safeLimit;
  return { page: safePage, limit: safeLimit, skip };
};

export const buildSearchRegex = (query?: string) => {
  if (!query || !query.trim()) return null;
  const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(escaped, "i");
};

export const readCsvFile = async (path: string) => {
  const content = await fs.readFile(path, "utf-8");
  return content;
};

