import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.label,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating "liquid glass" tab bar (iOS 26 style).
///
/// * The bar is a blurred glass capsule with a light rim that floats above
///   the content.
/// * The selected tab sits under a glass **lens**: it magnifies and softly
///   blurs whatever is behind it (including the bar's own icon), and has a
///   specular rim.
/// * The lens is physical: a spring moves it between tabs, it stretches along
///   its direction of travel and squashes across it, overshoots and wobbles
///   as it settles, swells while pressed, and can be dragged with a finger
///   and flicked to a neighbouring tab.
///
/// Use as `Scaffold.bottomNavigationBar` on a Scaffold with `extendBody:
/// true`, and reserve [barHeight] + the bottom safe area at the end of any
/// scrolling content.
class AppTabBar extends StatefulWidget {
  const AppTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Height of the capsule itself.
  static const double capsuleHeight = 64;

  /// Gap between the capsule and the bottom safe area.
  static const double bottomGap = 8;

  /// Space the bar takes above the bottom safe area; use for content padding.
  static const double barHeight = capsuleHeight + bottomGap;

  final List<AppTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> with TickerProviderStateMixin {
  /// Slightly under-damped so the lens overshoots and wobbles like liquid.
  static const SpringDescription _spring =
      SpringDescription(mass: 1, stiffness: 320, damping: 20);

  static const double _inset = 5;

  /// The glass capsule's own 1px rim; content starts inside it.
  static const double _rim = 1;

  /// Offset from the capsule's edge to the first cell.
  static const double _pad = _inset + _rim;

  /// Lens position in *visual* tab units (0 = leftmost tab on screen).
  late final AnimationController _move = AnimationController.unbounded(
    vsync: this,
  )..addListener(_trackVelocity);

  /// 0 → idle, 1 → pressed/dragged (lens swells and magnifies more).
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 420),
  );

  bool _ready = false;
  bool _rtl = false;
  bool _dragging = false;
  double _target = 0;
  double _cell = 1;
  int _hapticVisual = -1;

  // Smoothed lens velocity (tabs/second), used for squash and stretch.
  double _vel = 0;
  double _lastPos = 0;
  int _lastMicros = 0;

  int get _n => widget.items.length;
  double _visual(int logical) => (_rtl ? _n - 1 - logical : logical).toDouble();
  int _logical(int visual) => _rtl ? _n - 1 - visual : visual;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (!_ready || rtl != _rtl) {
      _rtl = rtl;
      _ready = true;
      _target = _visual(widget.currentIndex);
      _move.value = _target;
      _lastPos = _target;
    }
  }

  @override
  void didUpdateWidget(AppTabBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex && !_dragging) {
      final t = _visual(widget.currentIndex);
      if ((t - _target).abs() > 0.01) _springTo(t);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _press.dispose();
    super.dispose();
  }

  void _trackVelocity() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final dt = (now - _lastMicros) / 1e6;
    if (_lastMicros != 0 && dt > 0 && dt < 0.1) {
      final inst = (_move.value - _lastPos) / dt;
      _vel = _vel * 0.55 + inst * 0.45;
    } else {
      _vel = 0;
    }
    _lastPos = _move.value;
    _lastMicros = now;
  }

  void _springTo(double target, {double velocity = 0}) {
    _target = target;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.stop();
      _move.value = target;
      _vel = 0;
      return;
    }
    _move.animateWith(SpringSimulation(_spring, _move.value, target, velocity));
  }

  // --- Gestures -----------------------------------------------------------

  void _select(int visual) {
    final v = visual.clamp(0, _n - 1);
    final logical = _logical(v);
    if (logical != widget.currentIndex) HapticFeedback.selectionClick();
    _springTo(v.toDouble());
    widget.onTap(logical);
  }

  void _onTapUp(TapUpDetails d) {
    _press.reverse();
    _select(((d.localPosition.dx - _pad) / _cell).floor());
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _move.stop();
    _press.forward();
    _hapticVisual = _move.value.round();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _move.value = (_move.value + d.delta.dx / _cell).clamp(-0.2, _n - 0.8);
    final near = _move.value.round().clamp(0, _n - 1);
    if (near != _hapticVisual) {
      _hapticVisual = near;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    _press.reverse();
    final v = d.velocity.pixelsPerSecond.dx / _cell;
    final visual = (_move.value + v * 0.10).round().clamp(0, _n - 1);
    _springTo(visual.toDouble(), velocity: v);
    final logical = _logical(visual);
    if (logical != widget.currentIndex) widget.onTap(logical);
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final radius = BorderRadius.circular(AppTabBar.capsuleHeight / 2);
    final glass = dark ? const Color(0xFF1C1C1E) : Colors.white;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpace.screen + AppSpace.xs,
        0,
        AppSpace.screen + AppSpace.xs,
        bottom + AppTabBar.bottomGap,
      ),
      child: SizedBox(
        height: AppTabBar.capsuleHeight,
        child: LayoutBuilder(
          builder: (context, c) {
            _cell = (c.maxWidth - 2 * _pad) / _n;
            final innerH = c.maxHeight - 2 * _pad;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _press.forward(),
              onTapUp: _onTapUp,
              onTapCancel: () => _press.reverse(),
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: () {
                _dragging = false;
                _press.reverse();
                _springTo(_target);
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_move, _press]),
                builder: (context, _) {
                  final press = Curves.easeOut.transform(_press.value);
                  final pos = _move.value;
                  final stretch = (_vel.abs() * 0.07).clamp(0.0, 0.42);

                  // Lens geometry: stretch along travel, squash across it,
                  // and swell when pressed.
                  final lensW = (_cell - 8) * (1 + stretch + press * 0.10);
                  final lensH = innerH * (1 - stretch * 0.30 + press * 0.12);
                  final cx = _pad + (pos + 0.5) * _cell;
                  final cy = c.maxHeight / 2;

                  return Transform.scale(
                    scale: 1 + 0.025 * press,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _GlassCapsule(
                          radius: radius,
                          glass: glass,
                          dark: dark,
                          child: _Items(
                            items: widget.items,
                            pos: pos,
                            n: _n,
                            cell: _cell,
                            logical: _logical,
                            tint: p.tint,
                            idle: p.secondaryLabel,
                            onSemanticTap: _select,
                            selectedLogical: widget.currentIndex,
                          ),
                        ),
                        Positioned(
                          left: cx - lensW / 2,
                          top: cy - lensH / 2,
                          width: lensW,
                          height: lensH,
                          child: IgnorePointer(
                            child: _Lens(
                              press: press,
                              stretch: stretch,
                              tint: p.tint,
                              dark: dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The blurred capsule body with specular rim and floating shadow.
class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({
    required this.radius,
    required this.glass,
    required this.dark,
    required this.child,
  });

  final BorderRadius radius;
  final Color glass;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: dark ? 0.28 : 0.95),
              Colors.white.withValues(alpha: dark ? 0.06 : 0.25),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTabBar.capsuleHeight / 2 - 1),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    glass.withValues(alpha: dark ? 0.55 : 0.60),
                    glass.withValues(alpha: dark ? 0.40 : 0.42),
                  ],
                ),
              ),
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icons and labels. Each item's colour blends toward the tint as the lens
/// approaches it, so colour follows the liquid rather than snapping.
class _Items extends StatelessWidget {
  const _Items({
    required this.items,
    required this.pos,
    required this.n,
    required this.cell,
    required this.logical,
    required this.tint,
    required this.idle,
    required this.onSemanticTap,
    required this.selectedLogical,
  });

  final List<AppTabItem> items;
  final double pos;
  final int n;
  final double cell;
  final int Function(int visual) logical;
  final Color tint;
  final Color idle;
  final ValueChanged<int> onSemanticTap;
  final int selectedLogical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_AppTabBarState._inset),
      child: Row(
        // Visual order is always left-to-right; logical order is mapped
        // per locale.
        textDirection: TextDirection.ltr,
        children: [
          for (var v = 0; v < n; v++)
            SizedBox(
              width: cell,
              child: _cell(v),
            ),
        ],
      ),
    );
  }

  Widget _cell(int v) {
    final item = items[logical(v)];
    final t = (1 - (pos - v).abs()).clamp(0.0, 1.0);
    final color = Color.lerp(idle, tint, t)!;
    final selected = logical(v) == selectedLogical;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: () => onSemanticTap(v),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(t > 0.5 ? item.selectedIcon : item.icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption2.copyWith(
              color: color,
              fontWeight: t > 0.5 ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// The glass lens: magnifies and softly blurs what is behind it, with a
/// specular rim and highlights painted on top.
class _Lens extends StatelessWidget {
  const _Lens({
    required this.press,
    required this.stretch,
    required this.tint,
    required this.dark,
  });

  final double press;
  final double stretch;
  final Color tint;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        // Magnify about the lens centre. More while pressed or moving fast.
        final scale = 1.14 + 0.16 * press + 0.10 * stretch;

        // RawMagnifier magnifies whatever is painted behind it (page, glass
        // capsule and its icon) in the correct coordinate space.
        return RawMagnifier(
          size: Size(w, h),
          magnificationScale: scale,
          decoration: MagnifierDecoration(
            shape: const StadiumBorder(),
            shadows: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: (dark ? 0.35 : 0.10) + 0.08 * press),
                blurRadius: 14 + 10 * press,
                offset: Offset(0, 4 + 3 * press),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(w, h),
            painter: _LensPainter(tint: tint, dark: dark, press: press),
          ),
        );
      },
    );
  }
}

class _LensPainter extends CustomPainter {
  _LensPainter({required this.tint, required this.dark, required this.press});

  final Color tint;
  final bool dark;
  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));

    // Body: faint milky glass, a touch of brand colour, lighter at the top.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.16 : 0.34 + 0.10 * press),
            Colors.white.withValues(alpha: dark ? 0.05 : 0.10),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = tint.withValues(alpha: 0.08 + 0.05 * press),
    );

    // Specular highlight hugging the top edge.
    final hi = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width * 0.14, 2.5, size.width * 0.72, size.height * 0.30),
      Radius.circular(size.height * 0.15),
    );
    canvas.drawRRect(
      hi,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.28 : 0.75),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(hi.outerRect),
    );

    // Rim: bright where light enters (top-start), faint across, brighter
    // again where it exits (bottom-end).
    canvas.drawRRect(
      rrect.deflate(0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.55 : 1.0),
            Colors.white.withValues(alpha: dark ? 0.08 : 0.18),
            Colors.white.withValues(alpha: dark ? 0.35 : 0.70),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_LensPainter old) =>
      old.press != press || old.dark != dark || old.tint != tint;
}
