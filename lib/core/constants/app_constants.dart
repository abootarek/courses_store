class AppConstants {
  // WhatsApp Configuration
  static const String whatsappNumber = '201234567890'; // Replace with actual admin WhatsApp number
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  
  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusApproved = 'approved';
  
  // Routes
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeUserHome = '/user-home';
  static const String routeAdminHome = '/admin-home';
  static const String routeAddCourse = '/add-course';
  static const String routeCourseDetails = '/course-details';
  
  // Firebase Collections
  static const String collectionUsers = 'users';
  static const String collectionCourses = 'courses';
  static const String collectionOrders = 'orders';
}
