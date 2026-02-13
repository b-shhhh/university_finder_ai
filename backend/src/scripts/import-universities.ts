import mongoose from "mongoose";
import { connectDatabase } from "../database/mongodb";
import { University } from "../models/university.model";
import { getCsvUniversities } from "../services/csv-data.service";

const slugify = (value: string) =>
  value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

const stableSourceId = (alpha2: string, name: string, rowId: string) => {
  const base = slugify(`${alpha2}-${name}`) || slugify(name) || `uni-${Date.now()}`;
  return `${base}-${rowId}`;
};

const legacySourceId = (alpha2: string, name: string) => {
  return slugify(`${alpha2}-${name}`) || slugify(name);
};

async function importUniversitiesFromCsv() {
  await connectDatabase();

  const rows = await getCsvUniversities();
  let created = 0;
  let updated = 0;

  for (const row of rows) {
    const sourceId = row.id;
    const payload = {
      sourceId,
      alpha2: row.alpha2,
      country: row.country,
      name: row.name,
      web_pages: row.web_pages,
      flag_url: row.flag_url,
      logo_url: row.logo_url,
      courses: Array.from(new Set((row.courses || []).map((course) => course.trim()).filter(Boolean))),
      description: `${row.name} in ${row.country} offers programs from imported data.`,
    };

    const existing = await University.findOne({
      $or: [
        { sourceId },
        { sourceId: stableSourceId(row.alpha2, row.name, row.id) },
        { sourceId: legacySourceId(row.alpha2, row.name) },
      ],
    }).select("_id");
    if (existing) {
      await University.updateOne({ _id: existing._id }, payload);
      updated += 1;
    } else {
      await University.create(payload);
      created += 1;
    }
  }

  console.log(`CSV import complete. Created: ${created}, Updated: ${updated}, Total rows: ${rows.length}`);
}

importUniversitiesFromCsv()
  .catch((error) => {
    console.error("Failed to import universities:", error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.connection.close();
  });
