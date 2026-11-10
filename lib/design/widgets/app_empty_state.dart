import 'package:flutter/material.dart';
import '../app_tokens.dart';
import '../app_type.dart';
import 'app_button.dart';

/// Centered icon + message for empty and error states, with an optional
/// action (e.g. Retry).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: p.tertiaryLabel),
            const SizedBox(height: AppSpace.md),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppType.title3.copyWith(color: p.label),
              ),
              const SizedBox(height: AppSpace.xxs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.subheadline.copyWith(color: p.secondaryLabel),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.md),
              AppButton(
                label: actionLabel!,
                style: AppButtonStyle.tinted,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
