import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design.dart';

/// Primary home actions as an evenly spaced row of icon tiles inside a single
/// grouped card: Quick donate, Campaigns, News.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onQuickDonate,
    required this.onCampaigns,
    required this.onNews,
  });

  final VoidCallback onQuickDonate;
  final VoidCallback onCampaigns;
  final VoidCallback onNews;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpace.md,
        horizontal: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Action(
              icon: CupertinoIcons.heart_fill,
              label: 'quick_donate'.tr(),
              filled: true,
              onTap: onQuickDonate,
            ),
          ),
          Expanded(
            child: _Action(
              icon: CupertinoIcons.square_grid_2x2_fill,
              label: 'view_campaigns'.tr(),
              onTap: onCampaigns,
            ),
          ),
          Expanded(
            child: _Action(
              icon: CupertinoIcons.news_solid,
              label: 'fund_news'.tr(),
              onTap: onNews,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedOpacity(
          opacity: _pressed ? 0.5 : 1,
          duration: AppMotion.fast,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.filled
                      ? p.tint
                      : p.tint.withValues(alpha: 0.14),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.filled ? Colors.white : p.tint,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xxs),
                child: Text(
                  widget.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption1.copyWith(color: p.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
