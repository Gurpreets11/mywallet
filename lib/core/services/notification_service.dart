import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'package:timezone/timezone.dart' as tz;

import 'dart:convert';

import '../../modules/expenses/screens/expense_list_screen.dart';
import '../../modules/income/screens/income_list_screen.dart';
import '../../modules/loans/repositories/loan_repository.dart';
import '../../modules/loans/screens/loan_detail_screen.dart';
import '../../modules/navigation/screens/main_navigation_screen.dart';
import 'navigation_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final LoanRepository _loanRepository = LoanRepository();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // await _notificationsPlugin.initialize(settings);

    await _notificationsPlugin.initialize(
      settings,

      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _handleNotificationTap(response.payload);
      },
    );

    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'wallet_channel',
        'Wallet Notifications',

        channelDescription: 'Financial reminders and alerts',

        importance: Importance.max,

        priority: Priority.high,
      ),
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(id, title, body, _notificationDetails());
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      payload: payload,
      tz.TZDateTime.from(scheduledDate, tz.local),

      _notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> scheduleDailyReminder() async {
    final now = DateTime.now();

    final scheduledDate = DateTime(now.year, now.month, now.day, 21, 0);

    await scheduleNotification(
      id: 999,

      title: 'Track Your Expenses',

      body: 'Don’t forget to update today’s expenses',

      scheduledDate: scheduledDate,
    );
  }

  /*Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null) {
      return;
    }

    final Map<String, dynamic> data = jsonDecode(payload);

    final String type = data['type'];

    if (type == 'loan') {
      final int loanId = data['loanId'];

      final loan = await _loanRepository.getLoanById(loanId);

      if (loan != null) {
        await NavigationService.instance.navigateTo(
          LoanDetailScreen(loan: loan),
        );
      }
    }
  }*/

  Future<void> _handleNotificationTap(String? payload) async {
    if (payload == null) {
      return;
    }

    final Map<String, dynamic> data = jsonDecode(payload);

    final String type = data['type'];

    switch (type) {
      case 'loan':
        final int loanId = data['loanId'];

        final loan = await _loanRepository.getLoanById(loanId);

        if (loan != null) {
          await NavigationService.instance.navigateTo(
            LoanDetailScreen(loan: loan),
          );
        }

        break;

      case 'expense':
        await NavigationService.instance.navigateTo(const ExpenseListScreen());
        break;

      case 'investment':
        // await NavigationService.instance.navigateTo(const InvestmentListScreen(),);
        break;

      case 'income':
        await NavigationService.instance.navigateTo(const IncomeListScreen());
        break;

      default:
        await NavigationService.instance.navigateTo(
          const MainNavigationScreen(),
        );
    }
  }

  Future<void> handleInitialNotification() async {
    final details = await _notificationsPlugin
        .getNotificationAppLaunchDetails();

    if (details == null) {
      return;
    }

    if (details.didNotificationLaunchApp &&
        details.notificationResponse?.payload != null) {
      await _handleNotificationTap(details.notificationResponse!.payload);
    }
  }

  Future<void> scheduleSipReminder({
    required int id,

    required String investmentName,

    required double amount,

    required int sipDate,
  }) async {
    final now = DateTime.now();

    DateTime scheduledDate = DateTime(now.year, now.month, sipDate, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = DateTime(now.year, now.month + 1, sipDate, 9, 0);
    }

    await scheduleNotification(
      id: id,

      title: 'SIP Reminder',

      body:
          '₹${amount.toStringAsFixed(0)} '
          'SIP due for '
          '$investmentName',

      scheduledDate: scheduledDate,

      payload: '''
{
  "type":"investment"
}
''',
    );
  }
}
