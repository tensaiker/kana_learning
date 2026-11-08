import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules one opt-in daily study reminder on the device itself.
/// Requires the AndroidManifest and Gradle setup described in README.md.
/// No backend, user account, Firebase, or internet connection is required.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _reminderId = 4201;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    if (_initialized || !_supported) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    tzdata.initializeTimeZones();
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
    _initialized = true;
  }

  /// Returns false when the OS denies permission or the platform is unsupported.
  /// Throws on a setup/scheduling error so the UI never reports false success.
  Future<bool> scheduleDaily({required int hour, required int minute}) async {
    if (!_supported) return false;
    await _initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        if (granted == false) return false;
      }
    } else {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        if (granted == false) return false;
      }
    }

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }

    // Reschedule the same ID so changing the time never creates duplicates.
    await _plugin.cancel(_reminderId);
    await _plugin.zonedSchedule(
      _reminderId,
      'A little Kana practice? 🍵',
      'Your cozy study session awaits. Learn a little Japanese today!',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cozy_kana_daily_study',
          'Daily study reminders',
          channelDescription: 'Gentle daily reminders to practice Kana',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Exact alarm permission is NOT requested for non-critical reminders.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> cancelReminder() async {
    if (!_supported) return;
    await _initialize();
    await _plugin.cancel(_reminderId);
  }
}
