class ApiEndpoints {
  // Base API URL (can be overridden with --dart-define=API_BASE_URL=https://api.example.com)
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5050/api',
  );

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const whoAmI = '/auth/whoami';
  static const updateProfile = '/auth/update-profile';
  static const changePassword = '/auth/change-password';
  static const deleteAccount = '/auth/delete-account';
  static const requestPasswordReset = '/auth/request-password-reset';
  static const resetPassword = '/auth/reset-password';

  // Users
  static const userProfile = '/users/profile';

  // Universities & courses
  static const universities = '/universities';
  static const universityByCountry = '/universities/country';
  static const universityCourses = '/universities/courses';
  static const courses = '/courses';
  static const coursesByCountry = '/courses/country';

  // Saved universities
  static const savedUniversities = '/saved-universities';

  // Recommendations
  static const recommendations = '/recommendations';
}
