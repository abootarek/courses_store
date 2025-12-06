import 'package:equatable/equatable.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/lesson_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<CourseModel> courses;
  final List<OrderModel> orders;
  final int pendingOrdersCount;
  final double totalRevenue;

  const AdminLoaded({
    required this.courses,
    required this.orders,
    required this.pendingOrdersCount,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [courses, orders, pendingOrdersCount, totalRevenue];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

class CourseAdded extends AdminState {}

class LessonsLoaded extends AdminState {
  final List<LessonModel> lessons;

  const LessonsLoaded(this.lessons);

  @override
  List<Object?> get props => [lessons];
}
