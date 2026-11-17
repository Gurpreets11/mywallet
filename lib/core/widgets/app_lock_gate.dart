import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/app_data_refresher.dart';
import '../services/backup/backup_service.dart';
import '../services/backup/data_reset_service.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';
import '../services/security/app_lock_service.dart';
import '../services/settings/app_preferences.dart';
import '../theme/app_colors.dart';
import 'pin_pad.dart';
import 'type_to_confirm_dialog.dart';

/// Wraps the whole app (use it in `MaterialApp.builder`). While the app lock is
/// on and the app is locked, a PIN screen covers everything. The app locks on
/// cold start and after being in the background longer than
/// [AppLockService.backgroundGracePeriod].
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final AppLockService _lock = AppLockService.instance;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Safety net: normally main() already loaded the lock state.
    _lock.ensureLoaded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lock.isEnabled) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // System pickers (backup / restore / export) also background the app.
        _backgroundedAt ??= _lock.isSuspended ? null : DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            DateTime.now().difference(since) >=
                AppLockService.backgroundGracePeriod) {
          _lock.lockNow();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lock,
      builder: (context, _) {
        return Stack(
          children: [
            widget.child,
            // Until the lock state is known, cover the app (no content flash).
            if (!_lock.isLoaded)
              const Positioned.fill(
                child: ColoredBox(color: AppColors.background),
              )
            else if (_lock.isLocked)
              const Positioned.fill(child: _LockScreen()),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen();

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final AppLockService _lock = AppLockService.instance;
  String _pin = '';
  bool _error = false;
  bool _busy = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTickerIfLockedOut();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTickerIfLockedOut() {
    _ticker?.cancel();
    if (_lock.lockoutRemaining == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_lock.lockoutRemaining == null) t.cancel();
      setState(() {});
    });
  }

  void _onDigit(String digit) {
    if (_busy || _lock.lockoutRemaining != null) return;
    if (_pin.length >= AppLockService.pinLength) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length == AppLockService.pinLength) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  Future<void> _submit() async {
    // Let the last dot paint before the (short) hashing work runs.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    final ok = _lock.unlock(_pin);
    if (ok) return; // gate rebuilds without this screen
    setState(() {
      _pin = '';
      _error = true;
    });
    _startTickerIfLockedOut();
  }

  Future<void> _forgotPin() async {
    // This screen sits ABOVE the app's Navigator (it is built in
    // MaterialApp.builder), so dialogs must use the Navigator's own context.
    final navContext = NavigationService.instance.navigatorKey.currentContext;
    if (navContext == null) return;
    final confirmed = await TypeToConfirmDialog.show(
      navContext,
      title: 'Forgot PIN?',
      message:
          'The PIN cannot be recovered. To get back in, ALL data in the app '
          'will be erased and the lock removed. A safety copy is saved first, '
          'and you can restore it (or an exported backup) from Settings.',
      confirmLabel: 'Erase & unlock',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final db = await AppDatabase.database;
      await BackupService(db).createSafetyBackup(reason: 'reset');
      await DataResetService(db).resetAllData(removeAppLock: true);
      await AppPreferences.instance.load();
      try {
        await NotificationService.instance.rescheduleAll();
      } catch (_) {}
      if (!mounted) return;
      await AppDataRefresher.refreshAll(context);
      // Last: this unlocks the app and removes this screen.
      await _lock.disable();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    }
  }

  String _lockoutText() {
    final left = _lock.lockoutRemaining;
    if (left == null) return '';
    final s = left.inSeconds + 1;
    return 'Too many attempts. Try again in ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final lockedOut = _lock.lockoutRemaining != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 20,
                  child: Text(
                    lockedOut
                        ? _lockoutText()
                        : _error
                        ? 'Wrong PIN. Try again.'
                        : '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PinDots(
                  length: AppLockService.pinLength,
                  filled: _pin.length,
                  hasError: _error,
                ),
                const SizedBox(height: 28),
                PinPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !_busy && !lockedOut,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _forgotPin,
                  child: const Text('Forgot PIN?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
