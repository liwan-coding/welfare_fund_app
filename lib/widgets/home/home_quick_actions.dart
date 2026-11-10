import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design.dart';

/// Primary home actions as an evenly spaced row of icon tiles inside a single
/// card: Quick donate (brand purple), Campaigns (brand teal), News.
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
              color: p.tint,
              filled: true,
              onTap: onQuickDonate,
            ),
          ),
          Expanded(
            child: _Action(
              icon: CupertinoIcons.square_grid_2x2_fill,
              label: 'view_campaigns'.tr(),
              color: p.secondary,
              onTap: onCampaigns,
            ),
          ),
          Expanded(
            child: _Action(
              icon: CupertinoIcons.news_solid,
              label: 'fund_news'.tr(),
              color: p.tint,
              onTap: onNews,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppPressable(
      semanticLabel: label,
      pressedScale: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : color.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              size: 26,
              color: filled ? Colors.white : color,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Padding(
            padding:
                const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xxs),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption1.copyWith(
                color: p.label,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
