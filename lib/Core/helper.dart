import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:next_level/Core/Adapter/color_adapter.dart';
import 'package:next_level/Core/Adapter/duration_adapter.dart';
import 'package:next_level/Core/Adapter/time_of_day_adapter.dart';
import 'package:next_level/General/Adapter/task_status_enum_adapter.dart';
import 'package:next_level/General/Adapter/task_type_enum_adapter.dart';
import 'package:next_level/General/Adapter/trait_type_enum_adapter.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/Widgets/sure_dialog.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class Helper {
  Future registerAdapters() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/NextLevel';
    await Directory(hivePath).create(recursive: true);
    Hive.initFlutter(hivePath);

    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());

    Hive.registerAdapter(RoutineModelAdapter());
    Hive.registerAdapter(ItemModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TraitModelAdapter());
    Hive.registerAdapter(SubTaskModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(TaskTypeEnumAdapter());
    Hive.registerAdapter(TraitTypeEnumAdapter());
    Hive.registerAdapter(TaskStatusEnumAdapter());
    Hive.registerAdapter(TaskLogModelAdapter());
  }

  Future<void> getDialog({
    String? title,
    required String message,
    bool withTimer = false,
    Function? onAccept,
    acceptButtonText,
  }) async {
    await Get.dialog(
      CustomDialogWidget(
        title: title,
        contentText: message,
        withTimer: withTimer,
        onAccept: onAccept,
        acceptButtonText: acceptButtonText,
      ),
    );
  }

  void getMessage({
    String? title,
    required String message,
    StatusEnum status = StatusEnum.SUCCESS,
    IconData? icon,
    Duration? duration,
    Function? onMainButtonPressed,
    String? mainButtonText,
  }) {
    Get.closeCurrentSnackbar();

    Get.snackbar(
      title ??
          (status == StatusEnum.WARNING
              ? LocaleKeys.Warning.tr()
              : status == StatusEnum.INFO
                  ? LocaleKeys.Info.tr()
                  : LocaleKeys.Success.tr()),
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.panelBackground.withValues(alpha: 0.9),
      animationDuration: const Duration(milliseconds: 400),
      duration: duration ?? const Duration(milliseconds: 1300),
      dismissDirection: DismissDirection.horizontal,
      icon: icon != null
          ? Icon(icon)
          : (status == StatusEnum.WARNING
              ? const Icon(
                  Icons.warning,
                  color: AppColors.red,
                )
              : status == StatusEnum.INFO
                  ? const Icon(Icons.info)
                  : const Icon(Icons.check)),
      mainButton: onMainButtonPressed != null
          ? TextButton(
              onPressed: () {
                onMainButtonPressed();
                Get.back();
              },
              child: Text(
                mainButtonText ?? "Okay",
                style: const TextStyle(color: AppColors.white),
              ),
            )
          : null,
    );
  }

  void getUndoMessage({
    required String message,
    required Function onUndo,
    Color? statusColor,
    String? statusWord,
  }) {
    Get.closeCurrentSnackbar();

    Get.snackbar(
      "",
      "",
      messageText: _buildRichMessage(message, statusColor, statusWord),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.panelBackground.withValues(alpha: 0.9),
      animationDuration: const Duration(milliseconds: 400),
      duration: const Duration(seconds: 3),
      dismissDirection: DismissDirection.horizontal,
      icon: const Icon(
        Icons.delete_rounded,
        color: AppColors.red,
      ),
      mainButton: TextButton(
        onPressed: () {
          onUndo();
          Get.back();
        },
        child: Text(
          "UNDO",
          style: TextStyle(
            color: AppColors.main,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      titleText: const SizedBox.shrink(), // Hide title
    );
  }

  Widget _buildRichMessage(String message, Color? statusColor, String? statusWord) {
    if (statusColor == null || statusWord == null) {
      return Text(
        message,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
      );
    }

    // Find the status word in the message and make it colored
    final lowerMessage = message.toLowerCase();
    final lowerStatusWord = statusWord.toLowerCase();
    final startIndex = lowerMessage.indexOf(lowerStatusWord);

    if (startIndex == -1) {
      return Text(
        message,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
        children: [
          if (startIndex > 0) TextSpan(text: message.substring(0, startIndex)),
          TextSpan(
            text: message.substring(startIndex, startIndex + statusWord.length),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (startIndex + statusWord.length < message.length) TextSpan(text: message.substring(startIndex + statusWord.length)),
        ],
      ),
    );
  }

  Future<bool> photosAccessRequest() async {
    // android sürüm 33 den büyük ise photos izni alınmalı yoksa storage izni yeterli
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt >= 33) {
      await Permission.photos.request();
      if (await Permission.photos.isGranted == false) {
        Helper().getMessage(
          message: "You must give permission to continue.",
          status: StatusEnum.WARNING,
        );
        return false;
      }

      if (await Permission.photos.isGranted == false) {
        if (await Permission.photos.isPermanentlyDenied) {
          Helper().getDialog(
            message: "You must grant access to the photos to continue.",
            onAccept: () async {
              await openAppSettings();
            },
          );
          return false;
        } else if (!await Permission.photos.isGranted) {
          Helper().getMessage(
            message: "You must grant access to the photos to continue.",
            status: StatusEnum.WARNING,
          );
          return false;
        }
      }
    } else {
      await Permission.storage.request();

      if (await Permission.storage.isGranted == false) {
        if (await Permission.storage.isPermanentlyDenied) {
          Helper().getDialog(
            message: "You must grant storage access to continue.",
            onAccept: () async {
              await openAppSettings();
            },
          );
          return false;
        } else if (!await Permission.storage.isGranted) {
          Helper().getMessage(
            message: "You must grant storage access to continue.",
            status: StatusEnum.WARNING,
          );
          return false;
        }
      }
    }

    return true;
  }

  Color getColorForPercentage(double percentage) {
    // Yüzdeye göre kırmızıdan yeşile renk gradyanı oluşturun
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;

    return Colors.red;
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Emoji Picker
  Future<String> showEmojiPicker(BuildContext context) async {
    late final String selectedEmoji;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 0.4.sh,
            child: EmojiPicker(
              onEmojiSelected: (emoji, category) {
                selectedEmoji = category.emoji;
                Get.back();
              },
              config: Config(
                bottomActionBarConfig: const BottomActionBarConfig(showBackspaceButton: false, enabled: false),
                categoryViewConfig: CategoryViewConfig(
                  extraTab: CategoryExtraTab.SEARCH,
                  backgroundColor: AppColors.panelBackground,
                ),
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: AppColors.panelBackground,
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.searchBar,
                  middle: EmojiPickerItem.categoryBar,
                  bottom: EmojiPickerItem.emojiView,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: AppColors.panelBackground,
                  buttonIconColor: AppColors.text,
                ),
              ),
            ),
          ),
        );
      },
    );

    return selectedEmoji;
  }

  Future<Color> selectColor() async {
    Color selectedColor = AppColors.main;

    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.brown,
      Colors.grey,
    ];

    await Get.dialog(
      AlertDialog(
        content: Wrap(
          children: List.generate(
            colors.length,
            (index) => InkWell(
              borderRadius: AppColors.borderRadiusAll,
              onTap: () {
                selectedColor = colors[index];
                Get.back();
              },
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: AppColors.borderRadiusAll,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return selectedColor;
  }

  Future<TimeOfDay?> selectTime(context, {TimeOfDay? initialTime}) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 12, minute: 0),
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );

    return selectedTime;
  }

  Future<DateTime?> selectDate({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    return selectedDate;
  }

  Future<DateTime?> selectDateWithQuickActions({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    return await showDialog<DateTime?>(
      context: context,
      builder: (BuildContext context) {
        DateTime? selectedDate = initialDate; // Initialize with initialDate

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(18),
              contentPadding: const EdgeInsets.all(12),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Direct calendar view with TableCalendar
                    SizedBox(
                      height: 323,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.text.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: TableCalendar<DateTime>(
                          locale: context.locale.toLanguageTag(),
                          rowHeight: 36,
                          firstDay: DateTime(1950),
                          lastDay: DateTime(2100),
                          focusedDay: selectedDate ?? DateTime.now(),
                          selectedDayPredicate: (day) => selectedDate != null && isSameDay(selectedDate!, day),
                          calendarFormat: CalendarFormat.month,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          availableGestures: AvailableGestures.horizontalSwipe,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.main,
                            ),
                            leftChevronIcon: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.main),
                            rightChevronIcon: Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.main),
                            headerPadding: const EdgeInsets.symmetric(vertical: 8),
                            headerMargin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.main.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text.withValues(alpha: 0.7),
                            ),
                            weekendStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text.withValues(alpha: 0.7),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: AppColors.main,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: selectedDate == null ? AppColors.main.withValues(alpha: 0.2) : AppColors.main.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: selectedDate == null ? Border.all(color: AppColors.main, width: 1) : null,
                            ),
                            defaultTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                            weekendTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                            selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                            todayTextStyle: TextStyle(fontSize: 14, color: AppColors.main, fontWeight: FontWeight.bold),
                            outsideTextStyle: TextStyle(fontSize: 14, color: AppColors.text.withValues(alpha: 0.4)),
                            cellMargin: const EdgeInsets.all(2),
                            cellPadding: EdgeInsets.zero,
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              selectedDate = selectedDay;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick action buttons
                    Row(
                      children: [
                        // Today button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(DateTime.now());
                            },
                            icon: const Icon(Icons.today_rounded),
                            label: const Text('Bugün'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.main.withValues(alpha: 0.1),
                              foregroundColor: AppColors.main,
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tomorrow button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(DateTime.now().add(const Duration(days: 1)));
                            },
                            icon: const Icon(Icons.event_rounded),
                            label: const Text('Yarın'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green.withValues(alpha: 0.1),
                              foregroundColor: AppColors.green,
                              elevation: 0,
                            ),
                          ),
                        ),
                        // Undated button
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Use epoch time as marker for dateless selection
                              Navigator.of(context).pop(DateTime.fromMillisecondsSinceEpoch(0));
                            },
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Tarihsiz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red.withValues(alpha: 0.1),
                              foregroundColor: AppColors.red,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('İptal'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.main,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: selectedDate != null
                      ? () {
                          Navigator.of(context).pop(selectedDate);
                        }
                      : null,
                  child: const Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
