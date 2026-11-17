import 'package:flutter/material.dart';

import '../../../core/services/security/app_lock_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pin_pad.dart';

/// What the PIN screen is being used for.
enum PinFlow {
  /// Create a new PIN and turn the lock on.
  enable,

  /// Enter the current PIN, then turn the lock off.
  disable,

  /// Enter the current PIN, then choose a new one.
  change,
}

/// Pops with `true` when the flow finished successfully, otherwise null/false.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.flow});

  final PinFlow flow;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Step { verifyCurrent, enterNew, confirmNew }

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AppLockService _lock = AppLockService.instance;
  late _Step _step;
  String _pin = '';
  String _firstEntry = '';
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _step = widget.flow == PinFlow.enable
        ? _Step.enterNew
        : _Step.verifyCurrent;
  }

  String get _title => switch (widget.flow) {
    PinFlow.enable => 'Set up app lock',
    PinFlow.disable => 'Turn off app lock',
    PinFlow.change => 'Change PIN',
  };

  String get _prompt => switch (_step) {
    _Step.verifyCurrent => 'Enter your current PIN',
    _Step.enterNew => 'Choose a ${AppLockService.pinLength}-digit PIN',
    _Step.confirmNew => 'Enter the new PIN again',
  };

  void _onDigit(String digit) {
    if (_busy || _pin.length >= AppLockService.pinLength) return;
    setState(() {
      _pin += digit;
      _message = null;
    });
    if (_pin.length == AppLockService.pinLength) _onComplete();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _message = null;
    });
  }

  Future<void> _onComplete() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;

    switch (_step) {
      case _Step.verifyCurrent:
        final wait = _lock.lockoutRemaining;
        if (wait != null) {
          _fail('Too many attempts. Try again in ${wait.inSeconds + 1}s');
          return;
        }
        if (!_lock.checkPin(_pin)) {
          _fail('Wrong PIN. Try again.');
          return;
        }
        if (widget.flow == PinFlow.disable) {
          setState(() => _busy = true);
          try {
            await _lock.disable();
          } catch (e) {
            if (!mounted) return;
            setState(() => _busy = false);
            _fail('Could not turn off the lock: $e');
            return;
          }
          if (mounted) Navigator.pop(context, true);
          return;
        }
        setState(() {
          _step = _Step.enterNew;
          _pin = '';
        });
        break;

      case _Step.enterNew:
        setState(() {
          _firstEntry = _pin;
          _pin = '';
          _step = _Step.confirmNew;
        });
        break;

      case _Step.confirmNew:
        if (_pin != _firstEntry) {
          setState(() {
            _firstEntry = '';
            _step = _Step.enterNew;
          });
          _fail('PINs did not match. Start again.');
          return;
        }
        setState(() => _busy = true);
        try {
          await _lock.setPin(_pin);
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _firstEntry = '';
            _step = _Step.enterNew;
          });
          _fail('$e');
          return;
        }
        if (mounted) Navigator.pop(context, true);
        break;
    }
  }

  void _fail(String message) {
    setState(() {
      _pin = '';
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _prompt,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 20,
                  child: Text(
                    _message ?? '',
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
                  hasError: _message != null,
                ),
                const SizedBox(height: 28),
                PinPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !_busy,
                ),
                if (widget.flow != PinFlow.disable) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'If you forget the PIN, the only way back in is to erase '
                    'all app data. Keep a backup file somewhere safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
