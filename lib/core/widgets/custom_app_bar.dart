import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final TextStyle? titleTextStyle;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.systemOverlayStyle,
    this.titleTextStyle,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title:
          titleWidget ??
          Text(
            title,
            style:
                titleTextStyle ??
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      systemOverlayStyle:
          systemOverlayStyle ??
          (theme.brightness == Brightness.light
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light),
      toolbarHeight: toolbarHeight,
      // Add subtle border at bottom
      bottom:
          bottom ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: theme.dividerColor.withAlpha((0.1 * 255).round()),
              height: 1,
            ),
          ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    bottom != null
        ? toolbarHeight + bottom!.preferredSize.height
        : toolbarHeight + 1,
  );

  // Factory constructor for a simple app bar with back button
  factory CustomAppBar.withBack({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    VoidCallback? onBack,
  }) {
    return CustomAppBar(
      title: title,
      actions: actions,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  // Factory constructor for a transparent app bar
  factory CustomAppBar.transparent({
    String? title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Widget? leading,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    return CustomAppBar(
      title: title ?? '',
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.dark,
    );
  }
}
