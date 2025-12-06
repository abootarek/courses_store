import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/add_course_screen.dart';
import '../../features/admin/presentation/screens/edit_course_screen.dart';
import '../../features/admin/presentation/screens/manage_lessons_screen.dart';
import '../../features/admin/presentation/screens/add_edit_lesson_screen.dart';
import '../../features/admin/presentation/screens/manage_orders_screen.dart';
import '../../features/user/presentation/screens/user_home_screen.dart';
import '../../features/user/presentation/screens/course_details_screen.dart';
import '../../features/shared/presentation/screens/settings_screen.dart';
import '../../data/models/course_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../di/dependency_injection.dart';

import '../../features/shared/presentation/screens/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/user-home',
        name: 'user-home',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/admin-home',
        name: 'admin-home',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/add-course',
        name: 'add-course',
        builder: (context, state) => const AddCourseScreen(),
      ),
      GoRoute(
        path: '/edit-course',
        name: 'edit-course',
        builder: (context, state) {
          final course = state.extra as CourseModel;
          return EditCourseScreen(course: course);
        },
      ),
      GoRoute(
        path: '/manage-lessons',
        name: 'manage-lessons',
        builder: (context, state) {
          final course = state.extra as CourseModel;
          return ManageLessonsScreen(course: course);
        },
      ),
      GoRoute(
        path: '/add-edit-lesson',
        name: 'add-edit-lesson',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return AddEditLessonScreen(
            courseId: params['courseId'] as String,
            lesson: params['lesson'] as LessonModel?,
          );
        },
      ),
      GoRoute(
        path: '/manage-orders',
        name: 'manage-orders',
        builder: (context, state) => const ManageOrdersScreen(),
      ),
      GoRoute(
        path: '/course-details',
        name: 'course-details',
        builder: (context, state) {
          final course = state.extra as CourseModel;
          return CourseDetailsScreen(course: course);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    redirect: (context, state) async {
      final authRepo = getIt<AuthRepository>();
      final isLoggedIn = authRepo.isLoggedIn();
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      final isSplash = state.uri.toString() == '/';

      if (isSplash) return null; // Allow splash screen to handle navigation

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        final user = await authRepo.getCurrentUser();
        if (user != null) {
          return user.role == 'admin' ? '/admin-home' : '/user-home';
        }
      }

      return null;
    },
  );
}
