import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_tokens.dart';
import '../app_type.dart';

/// Large-title navigation bar that collapses to a standard title on scroll.
/// Use as the first sliver inside a CustomScrollView.
class AppNavBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const AppNavBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final canPop = showBack && Navigator.of(context).canPop();

    return SliverAppBar(
      pinned: true,
      expandedHeight: 96,
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: canPop
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => Navigator.of(context).maybePop(),
              // chevron_back mirrors automatically in RTL.
              child: Icon(CupertinoIcons.chevron_back, color: p.tint),
            )
          : null,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, c) {
          final top = MediaQuery.paddingOf(context).top;
          final collapsed = c.maxHeight <= kToolbarHeight + top + 4;
          final t = ((c.maxHeight - kToolbarHeight - top) / (96 - kToolbarHeight))
              .clamp(0.0, 1.0);
          return Stack(
            children: [
              // Collapsed inline title
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Opacity(
                      opacity: collapsed ? 1 : 0,
                      child: Text(title,
                          style: AppType.headline.copyWith(color: p.label)),
                    ),
                  ),
                ),
              ),
              // Large title
              PositionedDirectional(
                start: AppSpace.screen,
                end: AppSpace.screen,
                bottom: 8,
                child: Opacity(
                  opacity: t,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.largeTitle.copyWith(color: p.label),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      shape: Border(
        bottom: BorderSide(
          color: p.separator.withValues(alpha: 0.0),
          width: 0.5,
        ),
      ),
    );
  }
}
