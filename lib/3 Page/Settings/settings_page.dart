import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/Widgets/language_pop.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/2%20General/accessible.dart';
import 'package:gamify_todo/2%20General/app_colors.dart';
import 'package:gamify_todo/5%20Service/hive_service.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/navigator_service.dart';
import 'package:gamify_todo/6%20Provider/store_provider.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/6%20Provider/theme_provider.dart';
import 'package:gamify_todo/6%20Provider/trait_provider.dart';
import 'package:gamify_todo/8%20Model/user_model.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.Settings.tr()),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            NavigatorService().back();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _settingsOption(
              title: LocaleKeys.SelectLanguage.tr(),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const LanguageSelectionPopup(),
                );
              },
            ),
            _settingsOption(
              title: "Tema Seçimi",
              subtitle: "Koyu/Açık temayı değiştirin.",
              onTap: () {
                context.read<ThemeProvider>().changeTheme();
              },
              trailing: Switch.adaptive(
                value: AppColors.isDark,
                thumbIcon: AppColors.isDark
                    ? WidgetStateProperty.all(
                        const Icon(
                          Icons.brightness_2,
                          color: AppColors.black,
                        ),
                      )
                    : WidgetStateProperty.all(
                        const Icon(
                          Icons.wb_sunny,
                          color: AppColors.white,
                        ),
                      ),
                trackOutlineColor: AppColors.isDark ? WidgetStateProperty.all(AppColors.transparent) : WidgetStateProperty.all(AppColors.dirtyRed),
                inactiveThumbColor: AppColors.dirtyRed,
                inactiveTrackColor: AppColors.white,
                onChanged: (_) {
                  context.read<ThemeProvider>().changeTheme();
                },
              ),
            ),
            _settingsOption(
              title: LocaleKeys.Help.tr(),
              subtitle: LocaleKeys.HelpText.tr(),
              onTap: () {
                yardimDialog(context);
              },
            ),
            _settingsOption(
              title: "Export",
              onTap: () async {
                await HiveService().exportData();
              },
            ),
            _settingsOption(
              title: "Import",
              onTap: () async {
                await HiveService().importData();
              },
            ),
            _settingsOption(
              title: LocaleKeys.DeleteAllData.tr(),
              color: AppColors.red,
              onTap: () async {
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
                    },
                    acceptButtonText: LocaleKeys.Yes.tr(),
                    title: "Hurra?");
              },
            ),
            _settingsOption(
              title: LocaleKeys.Exit.tr(),
              color: AppColors.red,
              onTap: () {
                NavigatorService().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> yardimDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          LocaleKeys.Help.tr(),
        ),
        content: Text(
          // TODO:
          LocaleKeys.HelpDialog.tr(),
        ),
      ),
    );
  }

  Widget _settingsOption({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color ?? AppColors.panelBackground,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          child: Row(
            mainAxisAlignment: subtitle != null ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color != null ? AppColors.white : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ]
                ],
              ),
              const Spacer(),
              if (trailing != null) trailing
            ],
          ),
        ),
      ),
    );
  }
}
