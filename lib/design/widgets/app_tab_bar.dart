import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating "liquid glass" tab bar (iOS 26 style, as in WhatsApp/Instagram):
/// a blurred, translucent capsule with a light rim that floats above the
/// content, and a glass highlight pill that slides to the selected tab.
///
/// Use as `Scaffold.bottomNavigationBar` on a Scaffold with `extendBody:
/// true`, and reserve [barHeight] + the bottom safe area at the end of any
/// scrolling content.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Height of the capsule itself.
  static const double capsuleHeight = 64;

  /// Gap between the capsule and the bottom safe area.
  static const double bottomGap = 8;

  /// Space the bar takes above the bottom safe area; use for content padding.
  static const double barHeight = capsuleHeight + bottomGap;

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(capsuleHeight / 2);

    // Glass tones: a milky layer in light mode, a smoky one in dark mode.
    final glass = dark ? const Color(0xFF1C1C1E) : Colors.white;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpace.screen + AppSpace.xs,
        0,
        AppSpace.screen + AppSpace.xs,
        bottom + bottomGap,
      ),
      child: SizedBox(
        height: capsuleHeight,
        child: DecoratedBox(
          // Soft lift so the capsule reads as floating glass.
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.5 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          // Outer layer = the 1px specular rim: bright at the top edge,
          // fading toward the bottom, like light catching glass.
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.28 : 0.95),
                  Colors.white.withValues(alpha: dark ? 0.06 : 0.25),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(capsuleHeight / 2 - 1),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        glass.withValues(alpha: dark ? 0.55 : 0.60),
                        glass.withValues(alpha: dark ? 0.40 : 0.42),
                      ],
                    ),
                  ),
                  child: _GlassItems(
                    items: items,
                    currentIndex: currentIndex,
                    onTap: onTap,
                    tint: p.tint,
                    idle: p.secondaryLabel,
                    dark: dark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassItems extends StatelessWidget {
  const _GlassItems({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.tint,
    required this.idle,
    required this.dark,
  });

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color tint;
  final Color idle;
  final bool dark;

  static const double _inset = 5;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    // -1 .. 1 across the row; AlignmentDirectional mirrors it in RTL.
    final x = n <= 1 ? 0.0 : -1 + 2 * currentIndex / (n - 1);

    return Padding(
      padding: const EdgeInsets.all(_inset),
      child: Stack(
        children: [
          // Sliding glass highlight behind the selected item.
          AnimatedAlign(
            alignment: AlignmentDirectional(x, 0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      AppTabBar.capsuleHeight / 2 - _inset),
                  color: tint.withValues(alpha: dark ? 0.22 : 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.16 : 0.7),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: _TabButton(
                    item: items[i],
                    selected: i == currentIndex,
                    tint: tint,
                    idle: idle,
                    onTap: () {
                      if (i != currentIndex) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.tint,
    required this.idle,
    required this.onTap,
  });

  final AppTabItem item;
  final bool selected;
  final Color tint;
  final Color idle;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? widget.tint : widget.idle;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: Icon(
                  widget.selected
                      ? widget.item.selectedIcon
                      : widget.item.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.caption2.copyWith(
                  color: color,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
