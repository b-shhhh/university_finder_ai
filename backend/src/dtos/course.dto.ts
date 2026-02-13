// DTO for creating a new course
export interface CreateCourseDTO {
  name: string;           // Course name, e.g., "Computer Science"
  description?: string;   // Optional course description
}

// DTO for response when listing all courses
export interface CourseResponseDTO {
  id: string;
  name: string;
  description?: string;
}

// DTO for requesting countries by course
export interface CourseCountriesDTO {
  courseId: string;
}

// DTO for requesting universities by course
export interface CourseUniversitiesDTO {
  courseId: string;
}
