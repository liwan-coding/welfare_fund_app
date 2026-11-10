import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_tokens.dart';
import '../app_type.dart';

/// Grouped-form text field: label above, filled rounded field, inline error
/// text below (instead of a snackbar).
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppSpace.xxs, bottom: AppSpace.xs),
            child: Text(label!,
                style: AppType.footnote.copyWith(color: p.secondaryLabel)),
          ),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppType.body.copyWith(color: p.label),
          cursorColor: p.tint,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            enabledBorder: errorText == null
                ? null
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: p.destructive),
                  ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppSpace.xxs, top: AppSpace.xxs),
            child: Text(errorText!,
                style: AppType.footnote.copyWith(color: p.destructive)),
          ),
      ],
    );
  }
}
