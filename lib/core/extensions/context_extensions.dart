import 'package:flutter/material.dart';

/// Extension methods for BuildContext to provide convenient access to common properties
extension ContextExtensions on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get the current color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get the current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get the media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get the screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get the screen width
  double get screenWidth => screenSize.width;
  
  /// Get the screen height
  double get screenHeight => screenSize.height;
  
  /// Get the device pixel ratio
  double get devicePixelRatio => mediaQuery.devicePixelRatio;
  
  /// Get the padding (safe area)
  EdgeInsets get padding => mediaQuery.padding;
  
  /// Get the view insets (keyboard)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  
  /// Get the bottom safe area height
  double get bottomSafeArea => padding.bottom;
  
  /// Get the top safe area height
  double get topSafeArea => padding.top;
  
  /// Check if device is in landscape mode
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;
  
  /// Check if device is in portrait mode
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  
  /// Check if device is a tablet (width > 600)
  bool get isTablet => screenWidth > 600;
  
  /// Check if device is a phone
  bool get isPhone => !isTablet;
  
  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);
  
  /// Check if current locale is Korean
  bool get isKorean => locale.languageCode == 'ko';
  
  /// Check if current locale is English
  bool get isEnglish => locale.languageCode == 'en';
  
  /// Show a snackbar with the given message
  void showSnackBar(String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }
  
  /// Show an error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
    );
  }
  
  /// Show a success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
  
  /// Pop the current route
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  
  /// Push a new route
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
  
  /// Push and replace current route
  Future<T?> pushReplacement<T>(Widget page) => Navigator.of(this).pushReplacement<T, dynamic>(
    MaterialPageRoute(builder: (_) => page),
  );
  
  /// Push and clear all previous routes
  Future<T?> pushAndClearStack<T>(Widget page) => Navigator.of(this).pushAndRemoveUntil<T>(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}