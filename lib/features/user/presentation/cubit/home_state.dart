import 'package:equatable/equatable.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/lesson_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<CourseModel> courses;

  const HomeLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderCreated extends HomeState {}

class CoursePurchased extends HomeState {}

class CourseDetailsLoaded extends HomeState {
  final List<LessonModel> lessons;
  final bool isPurchased;
  final bool isPending;
  final bool isRejected;

  const CourseDetailsLoaded(
    this.lessons, 
    this.isPurchased, 
    {this.isPending = false, this.isRejected = false}
  );

  @override
  List<Object?> get props => [lessons, isPurchased, isPending, isRejected];
}
