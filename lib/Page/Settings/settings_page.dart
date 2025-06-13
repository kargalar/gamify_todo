import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Widgets/language_pop.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Settings/archived_routines_page.dart';
import 'package:next_level/Page/Settings/color_selection_dialog.dart';
import 'package:next_level/Page/Settings/contact_us_dialog.dart';
import 'package:next_level/Page/Settings/data_management_dialog.dart';
import 'package:next_level/Page/Settings/privacy_policy_dialog.dart';
import 'package:next_level/Page/Settings/task_style_selection_dialog.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/theme_provider.dart';
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
              icon: Icons.language,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const LanguageSelectionPopup(),
                );
              },
            ),
            _settingsOption(
              title: LocaleKeys.ThemeSelection.tr(),
              subtitle: LocaleKeys.ThemeSelectionSubtitle.tr(),
              icon: Icons.dark_mode,
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
              title: 'Archived Routines',
              subtitle: 'View your archived routines',
              icon: Icons.archive,
              onTap: () {
                NavigatorService().goTo(const ArchivedRoutinesPage());
              },
            ),
            _settingsOption(
              title: 'Task Style',
              subtitle: 'Change how task items are displayed',
              icon: Icons.palette,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const TaskStyleSelectionDialog(),
                );
              },
            ),
            Consumer<ColorProvider>(
              builder: (context, colorProvider, child) {
                return _settingsOption(
                  title: 'App Color Theme',
                  subtitle: 'Choose your preferred color: ${colorProvider.getColorName(colorProvider.currentColor)}',
                  icon: Icons.color_lens,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ColorSelectionDialog(),
                    );
                  },
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorProvider.currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.text.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            // _settingsOption(
            //   title: LocaleKeys.Help.tr(),
            //   subtitle: LocaleKeys.HelpText.tr(),
            //   onTap: () {
            //     yardimDialog(context);
            //   },
            // ),
            _settingsOption(
              title: LocaleKeys.DataManagement.tr(),
              subtitle: LocaleKeys.DataManagementSubtitle.tr(),
              icon: Icons.storage,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const DataManagementDialog(),
                );
              },
            ),
            _settingsOption(
              title: LocaleKeys.ContactUs.tr(),
              subtitle: LocaleKeys.ContactUsSubtitle.tr(),
              icon: Icons.contact_support,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const ContactUsDialog(),
                );
              },
            ),
            _settingsOption(
              title: LocaleKeys.PrivacyPolicy.tr(),
              subtitle: LocaleKeys.PrivacyPolicySubtitle.tr(),
              icon: Icons.privacy_tip,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const PrivacyPolicyDialog(),
                );
              },
            ),
            // TODO: for with database accounts
            // _settingsOption(
            //   title: LocaleKeys.Exit.tr(),
            //   color: AppColors.red,
            //   onTap: () {
            //     NavigatorService().logout();
            //   },
            // ),
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
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Ink(
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
              horizontal: 20,
            ),
            child: Row(
              mainAxisAlignment: subtitle != null ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: color != null ? AppColors.white : AppColors.main,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.left,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: color != null ? AppColors.white.withAlpha(180) : null,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                if (trailing != null) trailing
              ],
            ),
          ),
        ),
      ),
    );
  }
}
