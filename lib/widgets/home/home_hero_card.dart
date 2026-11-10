import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Brand card that straddles the header gradient and the content sheet.
///
/// Mirrors the Monzo balance card: a solid coloured surface with the primary
/// actions as translucent pills along its bottom edge.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.onQuickDonate,
    required this.onCampaigns,
    required this.onNews,
  });

  static const double height = 148;

  /// How far the card hangs over the top edge of the content sheet.
  static const double overlap = 36;

  final VoidCallback onQuickDonate;
  final VoidCallback onCampaigns;
  final VoidCallback onNews;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        border: Border.all(color: AppColors.surface.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withOpacity(0.38),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -60,
              end: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryLight.withOpacity(0.55),
                      AppColors.secondaryLight.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        color: AppColors.surface,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'app_title'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'help_achieve_hope'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionPill(
                          icon: CupertinoIcons.heart_fill,
                          label: 'quick_donate'.tr(),
                          onTap: onQuickDonate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.campaign,
                          label: 'view_campaigns'.tr(),
                          onTap: onCampaigns,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.newspaper_rounded,
                          label: 'fund_news'.tr(),
                          onTap: onNews,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDeep.withOpacity(0.42),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.surface, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
