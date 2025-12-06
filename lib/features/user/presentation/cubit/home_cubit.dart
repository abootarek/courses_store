import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/course_repository.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/models/order_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final CourseRepository courseRepository;
  final OrderRepository orderRepository;
  final AuthRepository authRepository;

  HomeCubit({
    required this.courseRepository,
    required this.orderRepository,
    required this.authRepository,
  }) : super(HomeInitial());

  Future<void> loadCourses() async {
    try {
      emit(HomeLoading());
      final courses = await courseRepository.getCourses();
      emit(HomeLoaded(courses));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await orderRepository.createOrder(order);
      emit(OrderCreated());
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> loadCourseDetails(String courseId) async {
    try {
      emit(HomeLoading());
      
      final lessons = await courseRepository.getLessonsByCourseId(courseId);
      final user = await authRepository.getCurrentUser();
      
      bool isPurchased = false;
      bool isPending = false;
      bool isRejected = false;
      
      if (user != null) {
        if (user.role == 'admin') {
          isPurchased = true;
        } else {
          final orders = await orderRepository.getOrdersByUserId(user.id);
          isPurchased = orders.any((order) => 
            order.courseId == courseId && order.status == 'approved'
          );
          if (!isPurchased) {
            isPending = orders.any((order) => 
              order.courseId == courseId && order.status == 'pending'
            );
            if (!isPending) {
              isRejected = orders.any((order) => 
                order.courseId == courseId && order.status == 'rejected'
              );
            }
          }
        }
      }

      emit(CourseDetailsLoaded(
        lessons, 
        isPurchased, 
        isPending: isPending,
        isRejected: isRejected,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
