import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../design/design.dart';

/// Immersive promo card: full-bleed photo, one bottom scrim for legibility,
/// text and a single white pill action anchored to the start-bottom corner.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.imageUrl,
    this.actionLabel,
    this.actionColor,
    this.onTap,
  });

  static const double height = 220;

  final String title;
  final String? eyebrow;
  final String? description;
  final String? imageUrl;
  final String? actionLabel;
  final Color? actionColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final url = imageUrl?.trim() ?? '';
    final hasAction = actionLabel != null && actionLabel!.isNotEmpty;

    return AppPressable(
      semanticLabel: title,
      pressedScale: 0.98,
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.tint,
          borderRadius: BorderRadius.circular(AppRadius.lg + 4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              AppNetworkImage(
                url,
                placeholder: (_) => const AppSkeleton(height: height, radius: 0),
                error: (_) => const _BrandBackdrop(),
              )
            else
              const _BrandBackdrop(),
            // One scrim, heavier at the bottom where the text sits.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.2, 1],
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                    Text(
                      eyebrow!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.footnote.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.title2.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.subheadline.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                  if (hasAction) ...[
                    const SizedBox(height: AppSpace.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                actionLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.subheadline.copyWith(
                                  color: actionColor ?? p.tint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Icon(
                              AppIcons.chevronForward,
                              size: 14,
                              color: actionColor ?? p.tint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback when there is no photo: deep brand purple with a soft teal glow,
/// so the card still reads as on-brand rather than empty.
class _BrandBackdrop extends StatelessWidget {
  const _BrandBackdrop();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Color.lerp(p.tint, Colors.black, 0.35)!),
        PositionedDirectional(
          top: -50,
          end: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.secondary.withValues(alpha: 0.35),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Icon(
              CupertinoIcons.sparkles,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
