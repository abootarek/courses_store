import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/repositories/course_repository.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NotificationCubit>()..loadNotifications(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NotificationError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return const Center(child: Text('No notifications yet.'));
              }
              return ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  final isRead = notification.isRead;
                  return Card(
                    color: isRead
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.1),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: isRead
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            notification.timestamp.toLocal().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () async {
                        context
                            .read<NotificationCubit>()
                            .markAsRead(notification.id);
                        if (notification.courseId != null &&
                            notification.courseId!.isNotEmpty) {
                          try {
                            // Fetch course details
                            final courseRepo = getIt<CourseRepository>();
                            final course = await courseRepo
                                .getCourseById(notification.courseId!);

                            if (course != null && context.mounted) {
                              context.push('/course-details', extra: course);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Could not open course: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
