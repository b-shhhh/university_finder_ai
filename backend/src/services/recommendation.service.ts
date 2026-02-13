import { getAllUniversitiesService } from "./university.service";

type RecommendationStat = {
  label: string;
  value: string;
};

type RecommendationItem = {
  id: string;
  name: string;
  program: string;
  country: string;
  countryImage: string;
  logoUrl: string;
  score: string;
  city: string;
  duration: string;
  tuition: string;
  ranking: string;
  intake: string;
  website: string;
  description: string;
};

type RecommendationDeadline = {
  title: string;
  date: string;
};

const scoreForId = (id: string) => {
  let hash = 0;
  for (let i = 0; i < id.length; i += 1) {
    hash = (hash * 31 + id.charCodeAt(i)) % 1000;
  }
  const value = 75 + (hash % 25);
  return `${value}%`;
};

const makeDate = (offsetDays: number) => {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  return date.toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" });
};

export const getRecommendationsService = async () => {
  const universities = await getAllUniversitiesService();

  const recommendations: RecommendationItem[] = universities.slice(0, 30).map((uni, index) => {
    const primaryProgram = uni.courses[0] || "General Studies";

    return {
      id: uni.id,
      name: uni.name,
      program: primaryProgram,
      country: uni.country,
      countryImage: uni.flag_url || "",
      logoUrl: uni.logo_url || "",
      score: scoreForId(uni.id),
      city: "N/A",
      duration: index % 2 === 0 ? "2 years" : "1.5 years",
      tuition: index % 3 === 0 ? "$25,000/year" : "$18,000/year",
      ranking: `#${20 + (index % 120)}`,
      intake: index % 2 === 0 ? "September" : "January",
      website: uni.web_pages || "",
      description: `${uni.name} offers ${primaryProgram} in ${uni.country}.`
    };
  });

  const countriesCount = new Set(recommendations.map((item) => item.country)).size;
  const coursesCount = new Set(recommendations.map((item) => item.program)).size;
  const topFit = recommendations[0]?.score || "0%";

  const stats: RecommendationStat[] = [
    { label: "Matches", value: String(recommendations.length) },
    { label: "Countries", value: String(countriesCount) },
    { label: "Courses", value: String(coursesCount) },
    { label: "Top Fit", value: topFit }
  ];

  const deadlines: RecommendationDeadline[] = [
    { title: "Application Document Review", date: makeDate(7) },
    { title: "Scholarship Submission", date: makeDate(14) },
    { title: "University Shortlist Finalization", date: makeDate(21) }
  ];

  return {
    stats,
    recommendations,
    deadlines
  };
};
