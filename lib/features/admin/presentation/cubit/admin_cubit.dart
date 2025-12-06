import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/course_repository.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/lesson_model.dart';
import '../../../../data/models/notification_model.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final CourseRepository courseRepository;
  final OrderRepository orderRepository;
  final NotificationRepository notificationRepository;

  AdminCubit({
    required this.courseRepository,
    required this.orderRepository,
    required this.notificationRepository,
  }) : super(AdminInitial());

  Future<void> loadDashboardData() async {
    try {
      emit(AdminLoading());

      final courses = await courseRepository.getCourses();
      final orders = await orderRepository.getAllOrders();
      final pendingCount = await orderRepository.getPendingOrdersCount();
      final revenue = await orderRepository.getTotalRevenue();

      emit(AdminLoaded(
        courses: courses,
        orders: orders,
        pendingOrdersCount: pendingCount,
        totalRevenue: revenue,
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> addCourse(CourseModel course) async {
    try {
      emit(AdminLoading());
      await courseRepository.addCourse(course);
      
      // Send Notification
      final notification = NotificationModel(
        id: '', // Repo generates ID
        title: 'New Course Added!',
        body: 'Check out the new course: ${course.title}',
        timestamp: DateTime.now(),
        courseId: course.id,
      );
      await notificationRepository.addNotification(notification);
      
      emit(CourseAdded());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateCourse(CourseModel course) async {
    try {
      emit(AdminLoading());
      await courseRepository.updateCourse(course);
      emit(CourseAdded()); // Re-use CourseAdded or create CourseUpdated if needed, but for now just stop emitting or emit success
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> approveOrder(String orderId) async {
    try {
      await orderRepository.updateOrderStatus(orderId, 'approved');
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await orderRepository.updateOrderStatus(orderId, 'rejected');
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await orderRepository.deleteOrder(orderId);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await courseRepository.deleteCourse(courseId);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ========== Lesson Management ==========

  Future<void> loadLessons(String courseId) async {
    try {
      emit(AdminLoading());
      final lessons = await courseRepository.getLessonsByCourseId(courseId);
      emit(LessonsLoaded(lessons));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> addLesson(LessonModel lesson) async {
    try {
      await courseRepository.addLesson(lesson);
      // Reload lessons
      await loadLessons(lesson.courseId);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateLesson(LessonModel lesson) async {
    try {
      await courseRepository.updateLesson(lesson);
      // Reload lessons
      await loadLessons(lesson.courseId);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteLesson(String lessonId, String courseId) async {
    try {
      await courseRepository.deleteLesson(lessonId, courseId);
      // Reload lessons
      await loadLessons(courseId);
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
