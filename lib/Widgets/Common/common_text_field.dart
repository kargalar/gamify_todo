import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';

/// Common text field widget with standardized styles
class CommonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;

  const CommonTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.style,
    this.hintStyle,
    this.labelStyle,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      style: style ?? TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: labelStyle ?? TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
        hintStyle: hintStyle ?? const TextStyle(color: AppColors.grey),
        border: border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.panelBackground2),
            ),
        enabledBorder: enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.panelBackground2),
            ),
        focusedBorder: focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.main),
            ),
        errorBorder: errorBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.red),
            ),
        filled: true,
        fillColor: AppColors.panelBackground,
      ),
    );
  }
}
