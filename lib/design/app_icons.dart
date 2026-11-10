import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'app_icons.dart';

/// Direction-aware icons. Flutter's AppIcons.chevronBack / _forward do
/// not mirror in RTL, so these copies set matchTextDirection.
class AppIcons {
  static const IconData chevronBack = IconData(
    0xf3cf,
    fontFamily: CupertinoIcons.iconFont,
    fontPackage: CupertinoIcons.iconFontPackage,
    matchTextDirection: true,
  );

  static const IconData chevronForward = IconData(
    0xf3d1,
    fontFamily: CupertinoIcons.iconFont,
    fontPackage: CupertinoIcons.iconFontPackage,
    matchTextDirection: true,
  );
}
