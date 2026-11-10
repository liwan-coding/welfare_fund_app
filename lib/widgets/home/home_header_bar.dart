import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../language_switcher.dart';

/// Top row of the home screen: avatar + greeting on the start side, language
/// switcher in a translucent pill on the end side.
class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.displayName,
    required this.onAvatarTap,
  });

  static const double height = 64;

  /// Signed-in user's name, or null for guests.
  final String? displayName;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim();
    final isGuest = name == null || name.isEmpty;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: isGuest ? 'login'.tr() : name,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: _Avatar(initial: isGuest ? null : name.characters.first),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'welcome'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface.withOpacity(0.78),
                    ),
                  ),
                  Text(
                    isGuest ? 'app_title'.tr() : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: const LanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.initial});

  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface.withOpacity(0.18),
        border: Border.all(color: AppColors.surface.withOpacity(0.55), width: 1.5),
      ),
      child: initial == null
          ? const Icon(CupertinoIcons.person, color: AppColors.surface, size: 22)
          : Text(
              initial!,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
