import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../design/design.dart';
import '../common/brand_emblem.dart';
import '../language_switcher.dart';

/// Home top area: brand emblem and greeting on the start side, language
/// switcher and avatar on the end side.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.displayName,
    required this.onAvatarTap,
  });

  /// Signed-in user's name, or null for guests.
  final String? displayName;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final name = displayName?.trim();
    final isGuest = name == null || name.isEmpty;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.screen,
        AppSpace.xs,
        AppSpace.screen,
        AppSpace.md,
      ),
      child: Row(
        children: [
          const BrandEmblem(size: 48),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome'.tr(),
                  style: AppType.footnote.copyWith(color: p.secondaryLabel),
                ),
                Text(
                  isGuest ? 'app_title'.tr() : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.title3.copyWith(color: p.label),
                ),
              ],
            ),
          ),
          LanguageSwitcher(color: p.tint),
          AppPressable(
            onTap: onAvatarTap,
            semanticLabel: isGuest ? 'login'.tr() : name,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.surface,
                    border: Border.all(color: p.separator, width: 0.5),
                  ),
                  child: isGuest
                      ? Icon(CupertinoIcons.person_fill,
                          color: p.tint, size: 18)
                      : Text(
                          name.characters.first,
                          style: AppType.headline.copyWith(color: p.tint),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

