import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (e) {
      print("Không set được location VN, dùng UTC");
    }

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // ĐOẠN CODE QUAN TRỌNG MỚI THÊM
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // 1. Xin quyền hiển thị thông báo (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // 2. Xin quyền đặt lịch chính xác (Sửa lỗi exact_alarms_not_permitted)
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.getLocation('Asia/Ho_Chi_Minh'),
    );

    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh')))) {
      return;
    }

    //  BỌC TRY-CATCH ĐỂ BẮT LỖI NẾU NGƯỜI DÙNG TỪ CHỐI QUYỀN
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Nhắc nhở',
            channelDescription: 'Thông báo nhắc nhở ghi chú',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Nếu vẫn lỗi, bạn có thể đổi thành: AndroidScheduleMode.inexactAllowWhileIdle
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: id.toString(),
      );
      print(" Đã đặt thông báo ID: $id");
    } catch (e) {
      print(" Lỗi đặt lịch: $e");
      // Nếu lỗi Exact Alarm, thử đặt lại bằng chế độ không chính xác (Fallback)
      if (e.toString().contains("exact_alarms_not_permitted")) {
        await _scheduleInexactNotification(id: id, title: title, body: body, scheduledTime: tzScheduledTime);
      }
    }
  }

  // Hàm dự phòng: Đặt lịch không chính xác (nếu không có quyền Exact)
  static Future<void> _scheduleInexactNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel', 'Nhắc nhở',
          importance: Importance.max, priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, //
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("⚠ Đã đặt thông báo (Chế độ Inexact) do thiếu quyền.");
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}