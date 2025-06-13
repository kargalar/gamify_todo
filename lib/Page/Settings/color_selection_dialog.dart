import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:provider/provider.dart';

class ColorSelectionDialog extends StatelessWidget {
  const ColorSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text('Select Main Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose your preferred app color theme:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ColorProvider.availableColors.map((color) {
                  final isSelected = colorProvider.currentColor == color;
                  return _buildColorOption(
                    context,
                    color,
                    isSelected,
                    colorProvider,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'The color will be applied throughout the app',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    Color color,
    bool isSelected,
    ColorProvider colorProvider,
  ) {
    return GestureDetector(
      onTap: () {
        colorProvider.changeColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 55 : 45,
        height: isSelected ? 55 : 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.text : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
