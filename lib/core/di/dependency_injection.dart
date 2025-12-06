import 'package:get_it/get_it.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
import '../../features/user/presentation/cubit/home_cubit.dart';
import '../../core/theme/theme_cubit.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<CourseRepository>(() => CourseRepository());
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepository());

  // Cubits
  getIt.registerFactory(() => AuthCubit(getIt()));
  getIt.registerFactory(() => HomeCubit(
        courseRepository: getIt(),
        orderRepository: getIt(),
        authRepository: getIt(),
      ));
  getIt.registerFactory(() => AdminCubit(
        courseRepository: getIt(),
        orderRepository: getIt(),
      ));
  getIt.registerSingleton<ThemeCubit>(ThemeCubit());
}
