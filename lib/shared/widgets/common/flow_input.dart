import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

class FlowInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final bool dense;

  const FlowInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.initialValue,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.label(context.cTextMuted)
                .copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          keyboardType: maxLines == 1 ? keyboardType : TextInputType.multiline,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          readOnly: readOnly,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: AppTypography.body(context.cTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 18,
                    color: context.cTextMuted,
                  )
                : null,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12,
              vertical: dense ? AppSpacing.sp8 : AppSpacing.sp10,
            ),
          ),
        ),
      ],
    );
  }
}

/// Simplified search input
class FlowSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const FlowSearchInput({
    super.key,
    this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.body(context.cTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: context.cTextMuted,
        ),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: context.cTextMuted,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12,
          vertical: AppSpacing.sp10,
        ),
      ),
    );
  }
}
