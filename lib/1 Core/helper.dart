import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamify_todo/1%20Core/Adapter/color_adapter.dart';
import 'package:gamify_todo/1%20Core/Adapter/duration_adapter.dart';
import 'package:gamify_todo/1%20Core/Adapter/time_of_day_adapter.dart';
import 'package:gamify_todo/2%20General/Adapter/task_status_enum_adapter.dart';
import 'package:gamify_todo/2%20General/Adapter/task_type_enum_adapter.dart';
import 'package:gamify_todo/2%20General/Adapter/trait_type_enum_adapter.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/8%20Model/routine_model.dart';
import 'package:gamify_todo/8%20Model/store_item_model.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
import 'package:gamify_todo/8%20Model/trait_model.dart';
import 'package:gamify_todo/8%20Model/user_model.dart';
import 'package:get/route_manager.dart';
import 'package:gamify_todo/1%20Core/Enums/status_enum.dart';
import 'package:gamify_todo/1%20Core/Widgets/sure_dialog.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class Helper {
  void registerAdapters() {
    Hive.initFlutter();

    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());

    Hive.registerAdapter(RoutineModelAdapter());
    Hive.registerAdapter(ItemModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TraitModelAdapter());
    Hive.registerAdapter(TaskTypeEnumAdapter());
    Hive.registerAdapter(TraitTypeEnumAdapter());
    Hive.registerAdapter(TaskStatusEnumAdapter());
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
      initialEntryMode: TimePickerEntryMode.dial,
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
}
