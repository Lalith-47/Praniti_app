class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:5000/api';
  static const String socketUrl = 'http://localhost:5000';
  
  // Azure Cosmos DB Configuration
  static const String cosmosDbConnectionString = 'AccountEndpoint=https://praniti-db.documents.azure.com:443/;AccountKey=your-account-key-here;';
  static const String cosmosDbDatabaseName = 'PranitiDB';
  static const String cosmosDbContainerUsers = 'Users';
  static const String cosmosDbContainerQuizzes = 'Quizzes';
  static const String cosmosDbContainerMessages = 'Messages';
  static const String cosmosDbContainerSessions = 'Sessions';
  
  // App Information
  static const String appName = 'Praniti';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String themeKey = 'theme_mode';
  
  // User Roles
  static const String mentorRole = 'mentor';
  static const String studentRole = 'student';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/me';
  static const String logoutEndpoint = '/auth/logout';
  
  // Student Endpoints
  static const String studentProfileEndpoint = '/student/profile';
  static const String studentQuizEndpoint = '/student/quiz';
  static const String studentResultsEndpoint = '/student/results';
  static const String studentMentorEndpoint = '/student/mentor';
  
  // Mentor Endpoints
  static const String mentorStudentsEndpoint = '/mentor/students';
  static const String mentorDashboardEndpoint = '/mentor/dashboard-stats';
  static const String mentorAnalyticsEndpoint = '/mentor/analytics';
  static const String mentorSessionsEndpoint = '/mentor/sessions';
  static const String mentorMessagesEndpoint = '/mentor/messages';
  
  
  // Chat Endpoints
  static const String chatMessagesEndpoint = '/chat/messages';
  static const String chatSendEndpoint = '/chat/send';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;
  static const int maxMessageLength = 1000;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Refresh Intervals
  static const Duration chatRefreshInterval = Duration(seconds: 5);
  static const Duration dashboardRefreshInterval = Duration(minutes: 1);
  static const Duration sessionTimeout = Duration(hours: 24);
}


