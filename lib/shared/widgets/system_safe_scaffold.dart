import 'package:flutter/material.dart';
import 'package:choice_lux_cars/app/theme.dart';

/// A Scaffold wrapper that automatically handles system UI insets
/// to prevent content from being hidden behind Android system navigation bar
class SystemSafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const SystemSafeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final safeAreaBottom = mediaQuery.viewPadding.bottom;

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor ?? ChoiceLuxTheme.jetBlack,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: body != null
          ? SafeArea(
              bottom: true,
              child: body!,
            )
          : null,
    );
  }
}

/// A Container wrapper that handles system UI insets for custom layouts
class SystemSafeContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;

  const SystemSafeContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final safeAreaBottom = mediaQuery.viewPadding.bottom;

    return Container(
      width: width,
      height: height,
      padding: padding != null
          ? EdgeInsets.only(
              top: padding!.top,
              left: padding!.left,
              right: padding!.right,
              bottom: padding!.bottom + (bottomPadding > 0 ? bottomPadding : 0),
            )
          : EdgeInsets.only(
              bottom: bottomPadding > 0 ? bottomPadding : 0,
            ),
      margin: margin,
      color: color,
      decoration: decoration,
      child: SafeArea(
        bottom: true,
        child: child,
      ),
    );
  }
}

/// A utility class for system UI inset handling
class SystemUIHelper {
  /// Get the bottom system UI inset (navigation bar height)
  static double getBottomInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom;
  }

  /// Get the top system UI inset (status bar height)
  static double getTopInset(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.top;
  }

  /// Get the total system UI insets
  static EdgeInsets getSystemInsets(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding;
  }

  /// Check if device has system navigation bar
  static bool hasSystemNavigationBar(BuildContext context) {
    return getBottomInset(context) > 0;
  }

  /// Get safe area for content (excluding system UI)
  static EdgeInsets getSafeArea(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }
}
