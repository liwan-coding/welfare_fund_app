import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../design/design.dart';
import '../../models/campaign.dart';

/// Campaign summary card: image on top, details below on a flat surface.
/// Text never sits on the photo, so contrast does not depend on the image.
class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  static const double _imageHeight = 168;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final lang = context.locale.languageCode;
    final done = campaign.isCompleted;
    final accent = done ? p.success : p.tint;
    final category = campaign.getLocalizedCategory(lang);
    final title = campaign.getLocalizedTitle(lang);
    final riyal = 'riyal'.tr();

    return AppPressable(
      semanticLabel: title,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'campaign-${campaign.id}',
              child: _CampaignImage(
                  url: campaign.imageUrl.trim(), height: _imageHeight),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (category.isNotEmpty ? category : 'campaign'.tr()),
                    style: AppType.footnote.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.headline.copyWith(color: p.label),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: campaign.progressPercentage.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: p.fill,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppFormat.amount(campaign.currentAmount)} $riyal',
                              style: AppType.subheadline.copyWith(
                                color: p.label,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              done
                                  ? 'campaign_goal_achieved'.tr()
                                  : '/ ${AppFormat.amount(campaign.targetAmount)} $riyal',
                              style: AppType.footnote
                                  .copyWith(color: p.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _StatusPill(done: done),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = done ? p.success : p.tint;
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.heart_fill,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            done ? 'completed'.tr() : 'donate_now'.tr(),
            style: AppType.footnote.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignImage extends StatelessWidget {
  const _CampaignImage({required this.url, required this.height});
  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget placeholder([Widget? child]) => Container(
          width: double.infinity,
          height: height,
          color: p.fill,
          alignment: Alignment.center,
          child: child ??
              Icon(CupertinoIcons.photo, color: p.tertiaryLabel, size: 32),
        );

    if (url.isEmpty) return placeholder();

    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(const AppActivityIndicator()),
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
}
