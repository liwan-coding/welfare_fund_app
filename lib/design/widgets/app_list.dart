import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../app_tokens.dart';
import '../app_type.dart';

/// Inset-grouped list section (iOS Settings style): optional small header,
/// rounded white group, hairline separators inset past the leading icon,
/// optional footer.
class AppListSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;

  const AppListSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(
          height: 0.5,
          thickness: 0.5,
          indent: AppSpace.md,
          color: p.separator,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.screen,
        end: AppSpace.screen,
        bottom: AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.md,
                bottom: AppSpace.xs,
              ),
              child: Text(
                header!,
                style: AppType.footnote.copyWith(color: p.secondaryLabel),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ColoredBox(
              color: p.surface,
              child: Column(children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.md,
                end: AppSpace.md,
                top: AppSpace.xs,
              ),
              child: Text(
                footer!,
                style: AppType.footnote.copyWith(color: p.secondaryLabel),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single row. Tappable rows get a pressed highlight and a chevron.
class AppListTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.destructive = false,
    bool? showChevron,
  }) : showChevron = showChevron ?? (onTap != null);

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final titleColor = widget.destructive ? p.destructive : p.label;

    Widget? lead = widget.leading;
    if (lead == null && widget.icon != null) {
      lead = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: widget.iconColor ?? p.tint,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(widget.icon, size: 18, color: Colors.white),
      );
    }

    final row = Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: _pressed ? p.fill : Colors.transparent,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead, const SizedBox(width: AppSpace.sm)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: AppType.body.copyWith(color: titleColor)),
                if (widget.subtitle != null)
                  Text(widget.subtitle!,
                      style: AppType.footnote.copyWith(color: p.secondaryLabel)),
              ],
            ),
          ),
          if (widget.value != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
              child: Text(widget.value!,
                  style: AppType.body.copyWith(color: p.secondaryLabel)),
            ),
          if (widget.trailing != null) ...[
            const SizedBox(width: AppSpace.xs),
            widget.trailing!,
          ],
          if (widget.showChevron)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
              child: Icon(AppIcons.chevronForward,
                  size: 16, color: p.tertiaryLabel),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return row;
    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: row,
      ),
    );
  }
}
