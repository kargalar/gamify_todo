import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/2%20General/accessible.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/5%20Service/hive_service.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/6%20Provider/trait_provider.dart';
import 'package:gamify_todo/8%20Model/user_model.dart';

class DataManagementDialog extends StatelessWidget {
  const DataManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.DataManagement.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dialogButton(
            icon: Icons.upload_file,
            title: LocaleKeys.ExportData.tr(),
            onTap: () async {
              await HiveService().exportData();
            },
          ),
          const SizedBox(height: 12),
          _dialogButton(
            icon: Icons.download,
            title: LocaleKeys.ImportData.tr(),
            onTap: () async {
              await HiveService().importData();
            },
          ),
          const SizedBox(height: 12),
          _dialogButton(
            icon: Icons.delete_forever,
            title: LocaleKeys.DeleteAllData.tr(),
            color: AppColors.red,
            onTap: () {
              Helper().getDialog(
                withTimer: true,
                message: LocaleKeys.DeleteAllDataWarning.tr(),
                onAccept: () async {
                  await HiveService().deleteAllData();

                  TaskProvider().taskList = [];
                  TaskProvider().routineList = [];
                  TraitProvider().traitList = [];
                  StoreProvider().storeItemList = [];
                  loginUser = UserModel(
                    id: 0,
                    email: "",
                    password: "",
                    creditProgress: Duration.zero,
                    userCredit: 0,
                  );
                  Navigator.pop(context);
                },
                acceptButtonText: LocaleKeys.Yes.tr(),
                title: "Hurra?",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dialogButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Ink(
      decoration: BoxDecoration(
        color: color ?? AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      child: InkWell(
        borderRadius: AppColors.borderRadiusAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color != null ? AppColors.white : null,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color != null ? AppColors.white : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
