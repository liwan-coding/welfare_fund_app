import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

/// Horizontally scrolling single-select filter chips. Selected chip is
/// tint-filled; the others sit on a neutral fill.
class AppChipBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.xs),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return Semantics(
            button: true,
            selected: selected,
            label: labels[i],
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!selected) HapticFeedback.selectionClick();
                onSelected(i);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? p.tint : p.fill,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  labels[i],
                  style: AppType.subheadline.copyWith(
                    color: selected ? Colors.white : p.label,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
