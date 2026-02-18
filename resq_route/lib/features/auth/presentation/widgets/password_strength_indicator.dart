import 'package:flutter/material.dart';

/// Password strength indicator widget.
///
/// Shows a visual bar and label that updates in real-time
/// as the user types their password.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength.value,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strength.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: strength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) {
      return _PasswordStrength(0, 'Enter password', Colors.grey);
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%\^&\*\(\),\.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) {
      return _PasswordStrength(0.25, 'Weak', Colors.red);
    }
    if (score <= 3) {
      return _PasswordStrength(0.5, 'Fair', Colors.orange);
    }
    if (score <= 4) {
      return _PasswordStrength(0.75, 'Strong', Colors.lightGreen);
    }
    return _PasswordStrength(1.0, 'Very Strong', Colors.green);
  }
}

class _PasswordStrength {
  final double value;
  final String label;
  final Color color;

  _PasswordStrength(this.value, this.label, this.color);
}
