import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// SOS button with two trigger modes:
/// - **Hold 3 seconds** with animated progress ring
/// - **Double-tap** within 500 ms
///
/// Provides heavy haptic feedback on trigger.
class SOSButton extends StatefulWidget {
  /// Called when the SOS is confirmed via hold or double-tap.
  final VoidCallback onTriggered;

  const SOSButton({super.key, required this.onTriggered});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 3);

  bool _isHolding = false;
  double _holdProgress = 0;
  Timer? _holdTimer;
  DateTime? _lastTap;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    // Check for double-tap
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 500)) {
      _triggerSOS();
      return;
    }
    _lastTap = now;

    // Start hold
    setState(() => _isHolding = true);
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _holdProgress += 50 / _holdDuration.inMilliseconds;
        if (_holdProgress >= 1.0) {
          timer.cancel();
          _triggerSOS();
        }
      });
    });
  }

  void _onTapUp(TapUpDetails _) {
    _cancelHold();
  }

  void _onTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0;
      });
    }
  }

  void _triggerSOS() {
    _holdTimer?.cancel();
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isHolding = false;
        _holdProgress = 0;
      });
    }
    widget.onTriggered();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: _isHolding ? _holdProgress : 0,
                strokeWidth: 4,
                backgroundColor: AppColors.sosRed.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            // Button
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.sosRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosRed.withValues(alpha: 0.4),
                    blurRadius: _isHolding ? 20 : 10,
                    spreadRadius: _isHolding ? 4 : 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.sos, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
