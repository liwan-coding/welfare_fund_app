import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Full-bleed gradient that sits behind the scrolling home content.
///
/// Two soft radial glows (brand blue top-end, brand purple bottom-start) give
/// the flat linear gradient depth without introducing extra hues.
class HomeHeaderBackdrop extends StatelessWidget {
  const HomeHeaderBackdrop({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.headerGradient),
              ),
              PositionedDirectional(
                top: -height * 0.45,
                end: -height * 0.35,
                child: _Glow(
                  diameter: height * 1.2,
                  color: AppColors.secondary.withOpacity(0.42),
                ),
              ),
              PositionedDirectional(
                bottom: -height * 0.5,
                start: -height * 0.4,
                child: _Glow(
                  diameter: height * 1.1,
                  color: AppColors.primaryLight.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
