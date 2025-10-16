import 'package:flutter/material.dart';

extension RouteServiceExtension on BuildContext {
  Future<T?> push<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

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

  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  void popUntil(String routeName) {
    Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  }

  bool canPop() {
    return Navigator.of(this).canPop();
  }

  Future<T?> pushWidget<T extends Object?>(Widget widget) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute(builder: (context) => widget));
  }

  Future<T?> pushWidgetAndRemoveUntil<T extends Object?>(
    Widget widget, {
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (context) => widget),
      predicate ?? (route) => false,
    );
  }

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
