import 'package:flutter/material.dart';
import '../app_tokens.dart';

/// Fades and lifts its child in once, after [delay]. Use a growing delay on
/// consecutive sections for a staggered entrance. Skipped entirely when the
/// system "reduce motion" setting is on.
class AppReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  const AppReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
  });

  /// Stagger helper: item [index] starts `index * step` after the first.
  const AppReveal.staggered({
    super.key,
    required this.child,
    required int index,
    Duration step = const Duration(milliseconds: 60),
    this.offset = 16,
  }) : delay = step * index;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Tap target with a subtle scale-down while pressed, like iOS cards and
/// icons. Wraps any child; keeps its own hit area.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _down ? 0.85 : 1,
            duration: const Duration(milliseconds: 140),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Shimmering placeholder block for loading states.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final base = p.fill;
    final highlight = Color.lerp(p.fill, p.surface, 0.7)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reduce ? 0.5 : _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * t, 0),
              end: Alignment(-0.5 + 3 * t, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder shaped like [CampaignCard] while campaigns load.
class CampaignCardSkeleton extends StatelessWidget {
  const CampaignCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: 168, radius: 0),
          Padding(
            padding: EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 80, height: 12),
                SizedBox(height: AppSpace.xs),
                AppSkeleton(height: 18),
                SizedBox(height: AppSpace.xs),
                AppSkeleton(width: 180, height: 18),
                SizedBox(height: AppSpace.md),
                AppSkeleton(height: 6, radius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
