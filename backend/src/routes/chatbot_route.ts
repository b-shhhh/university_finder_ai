// app/api/chatbot/route.ts
import { NextRequest, NextResponse } from "next/server";
import { MongoClient } from "mongodb";
// Using Gemini via REST to avoid extra dependencies

// Ensure env var matches .env.local (MONGODB_URI)
const client = new MongoClient(process.env.MONGODB_URI ?? "");

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
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    err.status = resp.status;
    // mark 404 to let caller fall back
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    err.notFound = resp.status === 404;
    throw err;
  }

  const data = await resp.json();
  return data;
};

async function fetchUniversities(filters: any) {
  try {
    await client.connect();
    const db = client.db("university_guide");
    const collection = db.collection("universities");

    const query: any = {};

    if (filters.country) query.country = { $regex: new RegExp(filters.country, "i") };
    if (filters.course)
      query.courses = { $elemMatch: { $regex: new RegExp(filters.course, "i") } };
    if (filters.university)
      query.name = { $regex: new RegExp(filters.university, "i") };
    if (filters.degree_level)
      query.degreeLevels = { $elemMatch: { $regex: new RegExp(filters.degree_level, "i") } };
    if (filters.ielts_min) query.ieltsMin = { $lte: parseFloat(filters.ielts_min) };
    if (filters.sat_min) query.satMin = { $lte: parseFloat(filters.sat_min) };

    const results = await collection.find(query).limit(10).toArray();
    return results;
  } catch (err) {
    console.error("Mongo error:", err);
    return [];
  } finally {
    await client.close();
  }
}

export async function POST(req: NextRequest) {
  try {
    const { message } = await req.json();

    // 1️⃣ Call Gemini to extract intent & entities
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

    let filters = {};
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
      const uniMatch = message.match(/\b(university|college|uni)\s+of\s+([A-Z][\w\s]+)/i);
      const ieltsMatch = message.match(/ielts\s*([0-9.]+)/i);
      const satMatch = message.match(/sat\s*([0-9]+)/i);

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
      (filters as any).country ||
      (filters as any).course ||
      (filters as any).degree_level ||
      (filters as any).university;
    if (!hasFilters) {
      return NextResponse.json({
        reply:
          "Please tell me at least a country, course/major, or degree level so I can search universities.",
        universities: [],
      });
    }

    // 2️⃣ Fetch from MongoDB
    const universities = await fetchUniversities(filters);

    // 3️⃣ Format response for frontend
    let reply = "";
    if (universities.length === 0) {
      reply =
        "No universities found with those filters. Try specifying a country, course, and degree level.";
    } else {
      reply = "Here are some universities I found:\n\n";
      universities.forEach((uni: any, idx: number) => {
        const name = uni.name ?? "Unnamed";
        const country = uni.country ?? "Country N/A";
        const degree = Array.isArray(uni.degreeLevels)
          ? uni.degreeLevels.join(", ")
          : uni.degree_level ?? "N/A";
        const ielts = uni.ieltsMin ?? uni.ielts_min ?? "N/A";
        const sat =
          uni.satRequired === true || uni.sat_required === true
            ? uni.satMin ?? uni.sat_min ?? "N/A"
            : uni.satRequired === false || uni.sat_required === false
            ? "optional"
            : "N/A";
        reply += `${idx + 1}. ${name} — ${country} (${degree}) · IELTS ${ielts} · SAT ${sat}\n`;
      });
    }

    return NextResponse.json({ reply, universities });
  } catch (err) {
    console.error("Error:", err);
    return NextResponse.json({ reply: "Something went wrong.", universities: [] });
  }
}
