import 'package:flutter/material.dart';

class ButtonSize {
  static const double small = 32.0;
  static const double medium = 40.0;
  static const double large = 48.0;
}

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final ButtonType type;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.type = ButtonType.primary,
    this.width,
    this.height = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    switch (type) {
      case ButtonType.primary:
        return _PrimaryButton(
          onPressed: onPressed,
          text: text,
          width: width,
          height: height,
          isLoading: isLoading,
          icon: icon,
        );
      case ButtonType.secondary:
        return _SecondaryButton(
          onPressed: onPressed,
          text: text,
          width: width,
          height: height,
          isLoading: isLoading,
          icon: icon,
        );
      case ButtonType.outline:
        return _OutlineButton(
          onPressed: onPressed,
          text: text,
          width: width,
          height: height,
          isLoading: isLoading,
          icon: icon,
        );
    }
  }
}

enum ButtonType { primary, secondary, outline }

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const _PrimaryButton({
    required this.onPressed,
    required this.text,
    this.width,
    required this.height,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(text: text, isLoading: isLoading, icon: icon),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const _SecondaryButton({
    required this.onPressed,
    required this.text,
    this.width,
    required this.height,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
        child: _ButtonContent(text: text, isLoading: isLoading, icon: icon),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const _OutlineButton({
    required this.onPressed,
    required this.text,
    this.width,
    required this.height,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(text: text, isLoading: isLoading, icon: icon),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String text;
  final bool isLoading;
  final IconData? icon;

  const _ButtonContent({
    required this.text,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
      );
    }

    return Text(text);
  }
}
