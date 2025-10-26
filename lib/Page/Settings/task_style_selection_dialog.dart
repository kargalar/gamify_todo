import 'package:flutter/material.dart';

import 'package:next_level/Enum/task_item_style_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/task_style_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';

class TaskStyleSelectionDialog extends StatelessWidget {
  const TaskStyleSelectionDialog({super.key});

  TaskModel get _sampleTask => TaskModel(
        title: 'Sample Task',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 2,
      );

  TaskModel get _sampleTask2 => TaskModel(
        title: 'Another Sample Task',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: true,
        isAlarmOn: false,
        priority: 1,
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskStyleProvider>(
      builder: (context, styleProvider, child) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(LocaleKeys.SelectTaskStyle.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stil seçenekleri (isim + açıklama, radio button)
                  RadioGroup<TaskItemStyle>(
                    groupValue: styleProvider.currentStyle,
                    onChanged: (TaskItemStyle? value) {
                      if (value != null) styleProvider.changeStyle(value);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: TaskItemStyle.values
                          .map((style) => RadioListTile<TaskItemStyle>(
                                value: style,
                                title: Text(_getStyleName(style)),
                                subtitle: Text(_getStyleDescription(style)),
                                activeColor: AppColors.main,
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Seçili stilin gerçek önizlemesi
                  Text(LocaleKeys.Preview.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          IgnorePointer(
                            child: TaskItem(taskModel: _sampleTask),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            child: TaskItem(taskModel: _sampleTask2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocaleKeys.Close.tr()),
            ),
          ],
        );
      },
    );
  }

  // Önizleme yukarıda, seçenekler aşağıda değil; seçenekler üstte, seçili stilin TaskItem'ı altta gösteriliyor.

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
