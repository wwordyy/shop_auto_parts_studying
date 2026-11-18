import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final bool enabled;
  final VoidCallback onActivity;
  final VoidCallback onTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningBefore,
    required this.enabled,
    required this.onActivity,
    required this.onTimeout,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _logoutTimer;
  bool _showWarning = false;

  Duration get _warningAfter {
    final value = widget.timeout - widget.warningBefore;
    return value.isNegative ? Duration.zero : value;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.enabled) _restart();
  }

  @override
  void didUpdateWidget(covariant InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _cancel();
      if (_showWarning && mounted) setState(() => _showWarning = false);
      return;
    }
    if (!oldWidget.enabled && widget.enabled) _restart();
  }

  bool _onKey(KeyEvent event) {
    if (widget.enabled) _restart();
    return false;
  }

  void _restart() {
    _cancel();
    widget.onActivity();
    if (_showWarning && mounted) setState(() => _showWarning = false);
    _warningTimer = Timer(_warningAfter, () {
      if (mounted && widget.enabled) setState(() => _showWarning = true);
    });
    _logoutTimer = Timer(widget.timeout, () {
      if (!widget.enabled) return;
      widget.onTimeout();
    });
  }

  void _cancel() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _warningTimer = null;
    _logoutTimer = null;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _restart() : null,
      onPointerMove: widget.enabled ? (_) => _restart() : null,
      onPointerSignal: widget.enabled ? (_) => _restart() : null,
      child: Stack(
        children: [
          widget.child,
          if (_showWarning && widget.enabled)
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
          if (_showWarning && widget.enabled)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: Colors.transparent,
                  child: AlertDialog(
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    title: const Text('Сессия скоро завершится'),
                    content: Text(
                      'Вы будете выведены из системы через ${widget.warningBefore.inSeconds} секунд из-за бездействия.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: _restart,
                        child: const Text('Остаться'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
