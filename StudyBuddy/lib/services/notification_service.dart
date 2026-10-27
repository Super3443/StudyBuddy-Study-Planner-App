import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Local notification plugin
import 'package:timezone/timezone.dart' as tz; // Timezone-aware scheduling
import 'package:timezone/data/latest.dart' as tz; // Timezone database
import 'dart:async' show Completer, Timer; // Provides Completer and Timer for scheduling
import 'package:flutter_timezone/flutter_timezone.dart'; // Device timezone detection


// Handles scheduling and cancelling local notifications on the device
class NotificationService {
  // Single instance of the notification plugin shared across the app
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Completes when initialise() finishes so scheduling can wait for it.
  final Completer<void> _initCompleter = Completer<void>();

  // Stores debug timers so they can be cancelled when a task is deleted or edited
  final Map<int, Timer> _debugTimers = {};

  // Sets up the notification plugin with platform-specific settings
  Future<void> initialise() async {
    // Stops when the plugin has already been initialised.
    if (_initCompleter.isCompleted) return; // Prevents completing the future twice

    // Loads the timezone database so notifications fire at the correct local time
    tz.initializeTimeZones();

    // Detects the device's current timezone (returns TimezoneInfo in v5)
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    // Falls back to UTC when the device reports a timezone the database does not recognise.
    try {
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier)); // Sets the detected timezone
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/GMT')); // Falls back to GMT when the identifier is invalid
    }

    // Android notification icon must match a drawable resource in the app
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combines platform-specific settings into one initialisation object
    const settings = InitializationSettings(android: androidSettings);

    // Initialises the plugin with the combined settings
    await _plugin.initialize(settings: settings);

    // Requests permission to schedule exact alarms on Android 12+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // Requests permission to post notifications on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Signals that the plugin is ready for scheduling.
    _initCompleter.complete();
  }

  // Schedules a notification to fire at the task's start date and time
  Future<void> scheduleTaskNotification({
    required int id, // Unique notification ID for cancellation
    required String title, // The task title displayed in the notification
    required DateTime startDate, // The date and time the notification should fire
  }) async {
    // Waits for the plugin to finish initialising before scheduling.
    await _initCompleter.future;

    // Converts the task's start date to a timezone-aware time
    final scheduledTime = tz.TZDateTime.from(startDate, tz.local);

    // Skips scheduling if the task's start time has already passed
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Configures the Android notification appearance
    const androidDetails = AndroidNotificationDetails(
      'task_reminders', // Channel ID groups related notifications together
      'Task Reminders', // Channel name visible in device notification settings
      channelDescription: 'Notifications for upcoming study tasks', // Channel description
      importance: Importance.high, // Ensures the notification appears prominently
      priority: Priority.high, // Displays the notification at the top of the list
    );

    // Wraps the Android details for cross-platform use
    const details = NotificationDetails(android: androidDetails);

    // Schedules the notification through the plugin's alarm system
    await _plugin.zonedSchedule(
      id: id, // Unique notification ID for cancellation
      title: 'Task Starting: $title', // Notification title
      body: 'Your task "$title" is starting now', // Notification body
      scheduledDate: scheduledTime, // The timezone-aware time to fire the notification
      notificationDetails: details, // Android notification appearance settings
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Fires at exact time even in doze mode
    );

    // Debug fallback for emulator testing (AlarmManager doesn't fire on emulator)
    assert(() {
      _debugTimers[id]?.cancel(); // Cancels any existing timer for this task
      final delay = scheduledTime.difference(tz.TZDateTime.now(tz.local));
      if (delay.isNegative) return true;
      _debugTimers[id] = Timer(delay, () {
        _plugin.show(
          id: id,
          title: 'Task Starting: $title',
          body: 'Your task "$title" is starting now',
          notificationDetails: details,
        );
        _debugTimers.remove(id); // Cleans up after firing
      });
      return true;
    }());
  }

  // Cancels a previously scheduled notification using its unique ID
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id); // Removes the notification from the plugin's scheduler
    // Cancels the debug timer if running on emulator in debug mode
    assert(() {
      _debugTimers[id]?.cancel();
      _debugTimers.remove(id);
      return true;
    }());
  }
}