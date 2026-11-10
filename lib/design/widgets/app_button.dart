import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

enum AppButtonStyle { filled, tinted, plain, destructive }

/// iOS-style button: 50pt filled / tinted, or a plain text button.
/// Press feedback is an opacity change, with a light haptic on tap.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.filled,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = onPressed != null && !loading;

    late final Color bg;
    late final Color fg;
    switch (style) {
      case AppButtonStyle.filled:
        bg = p.tint;
        fg = Colors.white;
      case AppButtonStyle.tinted:
        bg = p.tint.withValues(alpha: 0.14);
        fg = p.tint;
      case AppButtonStyle.destructive:
        bg = p.destructive.withValues(alpha: 0.14);
        fg = p.destructive;
      case AppButtonStyle.plain:
        bg = Colors.transparent;
        fg = p.tint;
    }

    final child = loading
        ? CupertinoActivityIndicator(color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppSpace.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headline.copyWith(color: fg),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
          pressedOpacity: 0.6,
          onPressed: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          child: Container(
            width: expand ? double.infinity : null,
            constraints: BoxConstraints(
              minHeight: style == AppButtonStyle.plain ? 44 : 50,
            ),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
