import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// Common button widget with standardized styles
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(color: isPrimary ? AppColors.main : AppColors.grey),
            foregroundColor: isPrimary ? AppColors.main : AppColors.text,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppColors.main : AppColors.grey,
            foregroundColor: Colors.white,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

    final buttonChild = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? (isPrimary ? AppColors.main : AppColors.text) : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: buttonChild,
            ),
    );
  }
}
