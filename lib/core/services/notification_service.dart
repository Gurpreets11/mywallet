import '../utils/currency_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'package:timezone/timezone.dart' as tz;

import 'dart:convert';

import '../../modules/expenses/screens/expense_list_screen.dart';
import '../../modules/investments/repositories/investment_repository.dart';
import '../../modules/income/screens/income_list_screen.dart';
import '../../modules/loans/repositories/loan_repository.dart';
import '../../modules/loans/screens/loan_detail_screen.dart';
import '../../modules/navigation/screens/main_navigation_screen.dart';
import 'navigation_service.dart';
import 'settings/app_preferences.dart';

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

  /// Reads the `type` field out of a notification payload (or null).
  String? _payloadType(String? payload) {
    if (payload == null) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? decoded['type']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    DateTimeComponents? repeat,
  }) async {
    // Respect the reminder switches in Settings.
    final type = _payloadType(payload);
    final prefs = AppPreferences.instance;
    if (type == 'loan' && !prefs.emiRemindersEnabled) return;
    if (type == 'investment' && !prefs.sipRemindersEnabled) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      payload: payload,
      tz.TZDateTime.from(scheduledDate, tz.local),

      _notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,

      matchDateTimeComponents: repeat,
    );
  }

  /// Cancels every pending notification whose payload type is [type]
  /// ('loan' or 'investment').
  Future<void> cancelByType(String type) async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    for (final request in pending) {
      if (_payloadType(request.payload) == type) {
        await _notificationsPlugin.cancel(request.id);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static const int _dailyReminderId = 999;

  /// Schedules (or cancels) the daily "track your expenses" reminder using the
  /// on/off switch and time chosen in Settings. Repeats every day.
  Future<void> scheduleDailyReminder() async {
    final prefs = AppPreferences.instance;
    if (!prefs.dailyReminderEnabled) {
      await cancelNotification(_dailyReminderId);
      return;
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      prefs.dailyReminderHour,
      prefs.dailyReminderMinute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: _dailyReminderId,

      title: 'Track Your Expenses',

      body: 'Don’t forget to update today’s expenses',

      scheduledDate: scheduledDate,

      repeat: DateTimeComponents.time,
    );
  }

  /// Rebuilds every reminder from the current database and preferences.
  /// Use after a restore or reset, when the old reminders no longer match
  /// the data. Loan reminders use the loan id and SIP reminders use
  /// 1,000,000 + investment id as notification ids.
  Future<void> rescheduleAll() async {
    await _notificationsPlugin.cancelAll();
    await scheduleDailyReminder();

    final now = DateTime.now();

    final loans = await _loanRepository.getAllLoans();
    for (final loan in loans) {
      final id = loan.id;
      final next = loan.nextEmiDate == null
          ? null
          : DateTime.tryParse(loan.nextEmiDate!);
      if (id == null || next == null) continue;
      if (loan.loanStatus.toUpperCase() == 'CLOSED') continue;

      final remindAt = next.subtract(const Duration(days: 1));
      if (!remindAt.isAfter(now)) continue;

      await scheduleNotification(
        id: id,
        title: 'EMI Reminder',
        body: 'EMI payment due for ${loan.personName}',
        scheduledDate: remindAt,
        payload: jsonEncode({'type': 'loan', 'loanId': id}),
      );
    }

    final investments = await InvestmentRepository().getAllInvestments();
    for (final investment in investments) {
      final id = investment.id;
      final day = investment.sipDate;
      final amount = investment.sipAmount;
      if (id == null || !investment.isSip || day == null || amount == null) {
        continue;
      }
      await scheduleSipReminder(
        id: 1000000 + id,
        investmentName: investment.investmentName,
        amount: amount,
        sipDate: day,
      );
    }
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
          '${CurrencyUtils.simple(amount)} '
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
