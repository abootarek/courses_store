import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription? _notificationSubscription;

  NotificationCubit(this.notificationRepository) : super(NotificationInitial());

  void loadNotifications() {
    emit(NotificationLoading());
    _notificationSubscription?.cancel();
    _notificationSubscription = notificationRepository.getNotifications().listen(
      (notifications) {
        emit(NotificationLoaded(notifications));
      },
      onError: (error) {
        emit(NotificationError(error.toString()));
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationRepository.markAsRead(notificationId);
    } catch (e) {
      // Opt: emit error or just log
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
