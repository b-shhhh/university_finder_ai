// DTO for creating a new university
export interface CreateUniversityDTO {
  name: string;                 // University name
  country: string;              // Country name
  courses?: string[];           // Array of course IDs or names
  description?: string;         // Optional description
}

// DTO for response when listing universities
export interface UniversityResponseDTO {
  id: string;
  name: string;
  country: string;
  courses?: string[];
  website?: string;
}

// DTO for searching universities by country
export interface UniversityByCountryDTO {
  country: string;
}

// DTO for searching universities by course
export interface UniversityByCourseDTO {
  courseId: string;
}

// DTO for saving a university for a user
export interface SaveUniversityDTO {
  userId: string;
  universityId: string;
}
