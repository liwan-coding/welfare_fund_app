import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../design/widgets/app_tab_bar.dart';

/// The app's three root destinations (Home, My Donations, Settings),
/// shared by every screen that shows the bottom tab bar.
class MainTabBar extends StatelessWidget {
  const MainTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return AppTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        AppTabItem(
          icon: CupertinoIcons.house,
          selectedIcon: CupertinoIcons.house_fill,
          label: 'home'.tr(),
        ),
        AppTabItem(
          icon: CupertinoIcons.heart,
          selectedIcon: CupertinoIcons.heart_fill,
          label: 'my_donations'.tr(),
        ),
        AppTabItem(
          icon: CupertinoIcons.gear,
          selectedIcon: CupertinoIcons.gear_solid,
          label: 'settings'.tr(),
        ),
      ],
    );
  }
}
