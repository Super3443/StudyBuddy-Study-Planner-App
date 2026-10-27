import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod state management
import 'package:mbap_project/services/notification_service.dart'; // Notification service

// Provides a single instance of NotificationService to the app
final notificationServiceProvider = Provider((ref) => NotificationService());


// Manages notification scheduling through the service layer
final notificationProvider = Provider((ref) {
  final service = ref.read(notificationServiceProvider);
  return NotificationProvider(service);
});

// Delegates notification operations from screens to the service
class NotificationProvider {
  // Reference to the notification service that handles device-level scheduling
  final NotificationService _service;

  NotificationProvider(this._service);

  // Initialises the notification plugin with platform-specific settings
  Future<void> initialise() => _service.initialise();

  // Schedules a notification to fire at the task's start time
  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required DateTime startDate,
  }) => _service.scheduleTaskNotification(
    id: id,
    title: title,
    startDate: startDate,
  );

  // Cancels a previously scheduled notification
  Future<void> cancelNotification(int id) => _service.cancelNotification(id);

  
}

