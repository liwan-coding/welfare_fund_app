import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../app_tokens.dart';
import '../app_type.dart';

/// iOS search field: filled rounded field, magnifier prefix, clear button
/// that appears while there is text.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide.none,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppType.body.copyWith(color: p.label),
        cursorColor: p.tint,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppType.body.copyWith(color: p.secondaryLabel),
          prefixIcon:
              Icon(CupertinoIcons.search, color: p.secondaryLabel, size: 20),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(CupertinoIcons.xmark_circle_fill,
                      color: p.tertiaryLabel, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          isDense: true,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
