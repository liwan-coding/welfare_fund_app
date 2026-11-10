import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The square emblem cropped out of the full logo lockup.
class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.size = 48});

  final double size;

  // Emblem bounds inside assets/image/logo (2).png (600x350 px).
  static const double _srcW = 600, _srcH = 350;
  static const double _emblemX = 205, _emblemY = 25, _emblemSize = 195;

  @override
  Widget build(BuildContext context) {
    final s = size / _emblemSize;
    return Semantics(
      image: true,
      label: 'app_title'.tr(),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -_emblemX * s,
                top: -_emblemY * s,
                width: _srcW * s,
                height: _srcH * s,
                child: Image.asset(
                  'assets/image/logo (2).png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
