import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

/// OTP verification screen — 6-digit code entry with resend timer.
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otpCode = '';
  bool _isVerifying = false;
  bool _canResend = false;
  int _resendSeconds = 60;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendSeconds = 60;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifyOtp(phone: widget.phone, token: _otpCode);

      if (!mounted) return;
      context.go('/verify-identity');
    } catch (e) {
      setState(() {
        _error = 'Invalid OTP. Please try again.';
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendOtp(phone: widget.phone);
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend OTP')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedPhone =
        '${widget.phone.substring(0, 4)}****${widget.phone.substring(widget.phone.length - 2)}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sms_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Phone Number',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n$maskedPhone',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
              ],

              // OTP fields
              PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: theme.colorScheme.surface,
                  inactiveFillColor:
                      theme.colorScheme.surfaceContainerHighest,
                  selectedFillColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  activeColor: AppColors.primary,
                  inactiveColor: theme.colorScheme.outline,
                  selectedColor: AppColors.primary,
                ),
                animationDuration: const Duration(milliseconds: 200),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onCompleted: (v) {
                  _otpCode = v;
                  _verifyOtp();
                },
                onChanged: (value) {
                  _otpCode = value;
                },
              ),
              const SizedBox(height: 24),

              // Verify button
              FilledButton(
                onPressed: _isVerifying || _otpCode.length != 6
                    ? null
                    : _verifyOtp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('VERIFY',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code? ",
                      style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _canResend ? _resendOtp : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendSeconds}s',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
