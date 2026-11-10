import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

enum AppToastKind { info, success, error }

/// Replaces the 180 ad-hoc SnackBars: one consistent, themed, accessible toast.
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
  }) {
    final p = AppPalette.of(context);
    final (icon, color) = switch (kind) {
      AppToastKind.success => (CupertinoIcons.checkmark_circle_fill, p.success),
      AppToastKind.error => (CupertinoIcons.exclamationmark_circle_fill, p.destructive),
      AppToastKind.info => (CupertinoIcons.info_circle_fill, Colors.white),
    };
    if (kind == AppToastKind.error) HapticFeedback.mediumImpact();
    if (kind == AppToastKind.success) HapticFeedback.lightImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        margin: const EdgeInsetsDirectional.all(AppSpace.md),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(message, style: AppType.subheadline.copyWith(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

/// iOS alert. Returns true when the primary action is confirmed.
Future<bool> showAppAlert(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        if (cancelLabel != null)
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
        CupertinoDialogAction(
          isDefaultAction: !destructive,
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class AppSheetAction<T> {
  final String label;
  final T value;
  final bool destructive;
  const AppSheetAction(this.label, this.value, {this.destructive = false});
}

/// iOS action sheet. Returns the chosen value, or null when cancelled.
Future<T?> showAppActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<AppSheetAction<T>> actions,
  required String cancelLabel,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final a in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: a.destructive,
            onPressed: () => Navigator.of(ctx).pop(a.value),
            child: Text(a.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(cancelLabel),
      ),
    ),
  );
}

/// Platform-neutral spinner using the iOS activity indicator.
class AppActivityIndicator extends StatelessWidget {
  final double radius;
  const AppActivityIndicator({super.key, this.radius = 12});

  @override
  Widget build(BuildContext context) =>
      CupertinoActivityIndicator(radius: radius);
}
