import 'package:flutter/material.dart';

/// Extension on BuildContext to provide convenient navigation methods
extension RouteServiceExtension on BuildContext {
  /// Push a new route onto the navigator stack
  Future<T?> push<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push a new route and remove all previous routes
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Push a replacement route
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Pop the current route
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  /// Pop until a specific route
  void popUntil(String routeName) {
    Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  }

  /// Check if we can pop the current route
  bool canPop() {
    return Navigator.of(this).canPop();
  }

  /// Push a widget directly (for cases where we don't use named routes)
  Future<T?> pushWidget<T extends Object?>(Widget widget) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute(builder: (context) => widget));
  }

  /// Push a widget and remove all previous routes
  Future<T?> pushWidgetAndRemoveUntil<T extends Object?>(
    Widget widget, {
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (context) => widget),
      predicate ?? (route) => false,
    );
  }

  /// Push a replacement widget
  Future<T?> pushReplacementWidget<T extends Object?, TO extends Object?>(
    Widget widget, {
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (context) => widget),
      result: result,
    );
  }
}
