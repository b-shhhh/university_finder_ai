import { Router, Request, Response, NextFunction } from "express";
import { University } from "../models/university.model";

const router = Router();

const isQuotaError = (err: any) =>
  err?.status === 429 ||
  err?.code === "insufficient_quota" ||
  err?.response?.status === 429;

// Attempts to extract a JSON object from Gemini text replies (which may include fences like ```json ... ```).
const extractJson = (text: string): any => {
  const trimmed = text.trim();
  const fenceMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenceMatch ? fenceMatch[1].trim() : trimmed;

  // Find first {...} block if still contains extra prose
  const braceMatch = candidate.match(/{[\s\S]*}/);
  const jsonString = braceMatch ? braceMatch[0] : candidate;

  try {
    return JSON.parse(jsonString);
  } catch {
    return {};
  }
};

const callGemini = async (prompt: string) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error("Missing GEMINI_API_KEY");

  // Allow overriding model via env; default to a currently available model
  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0 },
    }),
  });

  if (!resp.ok) {
    const errorBody = await resp.text();
    const err = new Error(`Gemini error: ${resp.status} ${resp.statusText} - ${errorBody}`);
    // mimic quota detection for UI
    // @ts-ignore
    err.status = resp.status;
    // mark 404 to let caller fall back
    // @ts-ignore
    err.notFound = resp.status === 404;
    throw err;
  }

  const data = await resp.json();
  return data;
};

async function fetchUniversities(filters: any) {
  const query: any = {};

  if (filters.country) query.country = { $regex: new RegExp(filters.country, "i") };
  if (filters.course) query.courses = { $regex: new RegExp(filters.course, "i") };
  if (filters.university) query.name = { $regex: new RegExp(filters.university, "i") };
  if (filters.degree_level)
    query.degreeLevels = { $regex: new RegExp(filters.degree_level, "i") };
  if (filters.ielts_min !== null && filters.ielts_min !== undefined)
    query.ieltsMin = { $lte: Number(filters.ielts_min) };
  if (filters.sat_min !== null && filters.sat_min !== undefined)
    query.satMin = { $lte: Number(filters.sat_min) };

  return University.find(query).limit(10).lean();
}

router.post("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { message } = req.body;

    if (!message || typeof message !== "string") {
      return res
        .status(400)
        .json({ reply: "A 'message' string is required.", universities: [] });
    }

    const prompt = `
You are a university search assistant.
Extract the user's intent and filters from their message.
Respond ONLY with raw JSON (no markdown, no code fences).
Schema:
{
  "intent": "search_universities",
  "country": "<country name or empty>",
  "course": "<course/major/subject or empty>",
  "degree_level": "<Bachelor|Master|PhD|MBA|... or empty>",
  "university": "<university name if specified or empty>",
  "ielts_min": <number or null>,
  "sat_min": <number or null>
}
If information is not provided, return empty string for text fields and null for numbers.

User: "${message}"
    `;

    let filters: any = {};
    try {
      const geminiResp = await callGemini(prompt);
      const aiText = geminiResp?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
      filters = extractJson(aiText);
    } catch (err: any) {
      // If Gemini is down, 404 (model missing), or over quota, fall back to a very simple regex-based filter extraction
      if (isQuotaError(err) || err?.status === 429 || err?.notFound) {
        console.warn("Gemini availability/model issue, falling back to regex extraction.");
      } else {
        console.error("Gemini error or JSON parse error:", err);
      }

      const lower = message.toLowerCase();
      const possibleDegrees = ["bachelor", "master", "phd", "mba", "msc", "bsc"];
      const degree_level = possibleDegrees.find((d) => lower.includes(d)) || "";
      const countryMatch = message.match(/\b(?:in|for)\s+([A-Z][a-zA-Z]+)/);
      const uniMatch = message.match(/\b(university|college|uni)\s+of\s+([A-Z][\\w\\s]+)/i);
      const ieltsMatch = message.match(/ielts\\s*([0-9.]+)/i);
      const satMatch = message.match(/sat\\s*([0-9]+)/i);

      filters = {
        intent: "search_universities",
        country: countryMatch ? countryMatch[1] : "",
        university: uniMatch ? uniMatch[2].trim() : "",
        course: "",
        degree_level,
        ielts_min: ieltsMatch ? Number(ieltsMatch[1]) : null,
        sat_min: satMatch ? Number(satMatch[1]) : null,
      };
    }

    const hasFilters =
      filters.country || filters.course || filters.degree_level || filters.university;
    if (!hasFilters) {
      return res.json({
        reply:
          "Please tell me at least a country, course/major, or degree level so I can search universities.",
        universities: [],
      });
    }

    const universities = await fetchUniversities(filters);

    // Normalize minimal shape for frontend consumption
    const normalized = universities.map((uni: any) => ({
      id: uni._id?.toString?.() ?? "",
      name: uni.name ?? "Unnamed",
      country: uni.country ?? "N/A",
      degreeLevels: Array.isArray(uni.degreeLevels) ? uni.degreeLevels : [],
      ieltsMin: uni.ieltsMin ?? uni.ielts_min ?? null,
      satRequired:
        uni.satRequired === true || uni.sat_required === true
          ? true
          : uni.satRequired === false || uni.sat_required === false
          ? false
          : null,
      satMin: uni.satMin ?? uni.sat_min ?? null
    }));

    let reply = "";
    if (universities.length === 0) {
      reply =
        "No universities found with those filters. Try specifying a country, course, and degree level.";
    } else {
      reply = "Here are some universities I found:\\n\\n";
      normalized.forEach((uni: any, idx: number) => {
        const degree = uni.degreeLevels.length ? uni.degreeLevels.join(", ") : "N/A";
        const ielts = uni.ieltsMin ?? "N/A";
        const sat =
          uni.satRequired === true
            ? uni.satMin ?? "N/A"
            : uni.satRequired === false
            ? "optional"
            : "N/A";
        reply += `${idx + 1}. ${uni.name} - ${uni.country} (${degree}) | IELTS ${ielts} | SAT ${sat}\\n`;
      });
    }

    return res.json({ reply, universities: normalized });
  } catch (err) {
    return next(err);
  }
});

export default router;
