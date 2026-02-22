import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import mongoose from "mongoose";
import readline from "readline";

import { connectDatabase } from "../database/mongodb";
import { University } from "../models/university.model";

type CsvRow = Record<string, string>;

async function readCsv(filePath: string): Promise<CsvRow[]> {
  const rows: CsvRow[] = [];
  const input = fs.createReadStream(filePath, { encoding: "utf8" });
  const rl = readline.createInterface({ input, crlfDelay: Infinity });

  let headers: string[] = [];

  const parseLine = (line: string) => {
    const cells: string[] = [];
    let current = "";
    let inQuotes = false;
    for (let i = 0; i < line.length; i += 1) {
      const char = line[i];
      const next = line[i + 1];
      if (char === '"' && inQuotes && next === '"') {
        current += '"';
        i += 1;
        continue;
      }
      if (char === '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char === "," && !inQuotes) {
        cells.push(current);
        current = "";
        continue;
      }
      current += char;
    }
    cells.push(current);
    return cells.map((cell) => cell.trim());
  };

  let lineIndex = 0;
  for await (const raw of rl) {
    const cells = parseLine(raw);
    if (lineIndex === 0) {
      headers = cells;
      lineIndex += 1;
      continue;
    }
    const row: CsvRow = {};
    cells.forEach((cell, idx) => {
      row[headers[idx] || `col${idx}`] = cell;
    });
    rows.push(row);
    lineIndex += 1;
  }
  return rows;
}

const toNumber = (value: string | undefined) => {
  if (!value) return null;
  const num = Number(String(value).replace(/[^\d.-]/g, ""));
  return Number.isFinite(num) ? num : null;
};

const getFirst = (row: CsvRow, keys: string[]): string | undefined => {
  for (const key of keys) {
    const direct = row[key];
    if (direct !== undefined && String(direct).trim()) return direct;
    const lower = row[key.toLowerCase()];
    if (lower !== undefined && String(lower).trim()) return lower;
    const upper = row[key.toUpperCase()];
    if (upper !== undefined && String(upper).trim()) return upper;
  }
  return undefined;
};

const toBool = (value: string | undefined) => {
  if (!value) return undefined;
  const v = String(value).trim().toLowerCase();
  if (["1", "true", "yes", "y"].includes(v)) return true;
  if (["0", "false", "no", "n"].includes(v)) return false;
  return undefined;
};

dotenv.config();

(async () => {
  const filePath = path.resolve(__dirname, "../uploads/universities.csv");
  if (!fs.existsSync(filePath)) {
    console.error("universities.csv not found at", filePath);
    process.exit(1);
  }

  await connectDatabase();

  const rows = await readCsv(filePath);
  let count = 0;
  for (const [rowIndex, row] of rows.entries()) {
    const sourceId = String(
      getFirst(row, ["S/N", "\ufeffS/N", "id", "sourceId"]) || rowIndex + 1
    ).trim();

    const name = getFirst(row, ["University", "university", "name"]) || "";
    const country = getFirst(row, ["Country", "country"]) || "";
    const alpha2 = (getFirst(row, ["Country Code", "alpha2"]) || "").toUpperCase();
    const state = getFirst(row, ["State", "state"]) || undefined;
    const city = getFirst(row, ["City", "city"]) || undefined;
    const website = getFirst(row, ["Official Website", "website", "web_pages"]);
    const flagUrl = getFirst(row, ["Country Flag URL", "country_flag"]);
    const logoUrl = getFirst(row, ["University Logo URL", "university_logo"]);

    const courses = String(
      getFirst(row, ["Popular Courses / Degrees", "PopularCourses", "courses", "course"]) || ""
    )
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);

    const degreeLevels = String(getFirst(row, ["Degree Levels", "degree_level", "degree_levels"]) || "")
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);

    const update: Record<string, unknown> = {
      sourceId,
      name,
      country,
      web_pages: website,
      flag_url: flagUrl,
      logo_url: logoUrl,
      courses,
      degreeLevels: degreeLevels.length ? degreeLevels : undefined,
      ieltsMin: toNumber(getFirst(row, ["Typical IELTS", "ielts_min"])),
      satRequired: toBool(getFirst(row, ["SAT Required", "sat_required"])),
      satMin: toNumber(getFirst(row, ["Typical SAT (Accepted)", "sat_min"])),
      description: getFirst(row, ["Description", "description"]) || undefined,
    };

    if (alpha2) update.alpha2 = alpha2;
    if (state) update.state = state;
    if (city) update.city = city;

    await University.findOneAndUpdate(
      { sourceId },
      update,
      { returnDocument: "after", upsert: true, setDefaultsOnInsert: true }
    );
    count += 1;
  }

  console.log(`Imported/updated ${count} universities`);
  await mongoose.connection.close();
})();

