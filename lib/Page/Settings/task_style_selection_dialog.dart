import 'package:flutter/material.dart';

import 'package:next_level/Enum/task_item_style_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/task_style_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class TaskStyleSelectionDialog extends StatelessWidget {
  const TaskStyleSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.SelectTaskStyle.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.ChooseTaskStyle.tr(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Consumer<TaskStyleProvider>(
            builder: (context, styleProvider, child) {
              return Column(
                children: TaskItemStyle.values.map((style) {
                  return _buildStyleOption(
                    context,
                    style,
                    styleProvider.currentStyle == style,
                    styleProvider,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.Close.tr()),
        ),
      ],
    );
  }

  Widget _buildStyleOption(
    BuildContext context,
    TaskItemStyle style,
    bool isSelected,
    TaskStyleProvider styleProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            styleProvider.changeStyle(style);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.main.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.main : AppColors.text.withAlpha(30),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _getStyleIcon(style, isSelected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStyleName(style),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.main : AppColors.text,
                        ),
                      ),
                      Text(
                        _getStyleDescription(style),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.main,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getStyleIcon(TaskItemStyle style, bool isSelected) {
    IconData iconData;
    switch (style) {
      case TaskItemStyle.card:
        iconData = Icons.view_comfortable;
        break;
      case TaskItemStyle.minimal:
        iconData = Icons.view_list;
        break;
      case TaskItemStyle.flat:
        iconData = Icons.view_stream;
        break;
      case TaskItemStyle.glass:
        iconData = Icons.blur_on;
        break;
      case TaskItemStyle.modern:
        iconData = Icons.view_compact;
        break;
    }

    return Icon(
      iconData,
      color: isSelected ? AppColors.main : AppColors.text.withAlpha(150),
      size: 24,
    );
  }

  String _getStyleName(TaskItemStyle style) {
    switch (style) {
      case TaskItemStyle.card:
        return LocaleKeys.CardStyle.tr();
      case TaskItemStyle.minimal:
        return LocaleKeys.MinimalStyle.tr();
      case TaskItemStyle.flat:
        return LocaleKeys.FlatStyle.tr();
      case TaskItemStyle.glass:
        return LocaleKeys.GlassStyle.tr();
      case TaskItemStyle.modern:
        return LocaleKeys.ModernStyle.tr();
    }
  }

  String _getStyleDescription(TaskItemStyle style) {
    switch (style) {
      case TaskItemStyle.card:
        return LocaleKeys.CardStyleDesc.tr();
      case TaskItemStyle.minimal:
        return LocaleKeys.MinimalStyleDesc.tr();
      case TaskItemStyle.flat:
        return LocaleKeys.FlatStyleDesc.tr();
      case TaskItemStyle.glass:
        return LocaleKeys.GlassStyleDesc.tr();
      case TaskItemStyle.modern:
        return LocaleKeys.ModernStyleDesc.tr();
    }
  }
}
