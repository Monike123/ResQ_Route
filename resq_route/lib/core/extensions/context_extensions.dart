import 'package:flutter/material.dart';

/// Useful extensions on BuildContext for quick access to theme and navigation.
extension ContextExtensions on BuildContext {
  /// Quick access to the theme.
  ThemeData get theme => Theme.of(this);

  /// Quick access to the color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to the text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to MediaQuery size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Quick access to screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Quick access to screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Show a SnackBar with a message.
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
