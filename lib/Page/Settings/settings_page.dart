import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Widgets/language_pop.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Page/Settings/color_selection_dialog.dart';
import 'package:next_level/Page/Settings/contact_us_dialog.dart';
import 'package:next_level/Page/Settings/file_storage_management_page.dart';
import 'package:next_level/Page/Settings/privacy_policy_dialog.dart';
import 'package:next_level/Page/Settings/streak_settings_page.dart';
import 'package:next_level/Page/Settings/task_style_selection_dialog.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Provider/offline_mode_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/sync_manager.dart';
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
        child: ListView(
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
              title: LocaleKeys.SelectTaskStyle.tr(),
              subtitle: LocaleKeys.SelectTaskStyle.tr(),
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
                  title: LocaleKeys.SelectMainColor.tr(),
                  subtitle: "${LocaleKeys.ChooseColorTheme.tr()} ${colorProvider.getColorName(colorProvider.currentColor)}",
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
            // Vacation Mode option
            Consumer<VacationModeProvider>(
              builder: (context, vacationModeProvider, child) {
                return _settingsOption(
                  title: LocaleKeys.VacationMode.tr(),
                  subtitle: LocaleKeys.VacationModeSubtitle.tr(),
                  icon: Icons.beach_access,
                  onTap: () {
                    vacationModeProvider.toggleVacationMode();
                  },
                  trailing: Switch.adaptive(
                    value: vacationModeProvider.isVacationModeEnabled,
                    thumbIcon: vacationModeProvider.isVacationModeEnabled
                        ? WidgetStateProperty.all(
                            const Icon(
                              Icons.beach_access,
                              color: AppColors.white,
                              size: 16,
                            ),
                          )
                        : WidgetStateProperty.all(
                            const Icon(
                              Icons.work,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ),
                    trackOutlineColor: vacationModeProvider.isVacationModeEnabled ? WidgetStateProperty.all(AppColors.transparent) : WidgetStateProperty.all(AppColors.dirtyRed),
                    inactiveThumbColor: AppColors.dirtyRed,
                    inactiveTrackColor: AppColors.white,
                    onChanged: (_) {
                      vacationModeProvider.toggleVacationMode();
                    },
                  ),
                );
              },
            ),
            // Streak Settings option
            _settingsOption(
              title: LocaleKeys.StreakSettings.tr(),
              subtitle: LocaleKeys.StreakMinimumHoursDesc.tr(),
              icon: Icons.local_fire_department,
              onTap: () {
                NavigatorService().goTo(const StreakSettingsPage());
              },
            ),
            // _settingsOption(
            _settingsOption(
              title: LocaleKeys.DataManagement.tr(),
              subtitle: LocaleKeys.DataManagementSubtitle.tr(),
              icon: Icons.storage_rounded,
              onTap: () {
                NavigatorService().goTo(const FileStorageManagementPage());
              },
            ),
            // Cloud Sync section - only show if user is logged in and offline mode is disabled
            if (loginUser != null) ...[
              Consumer<OfflineModeProvider>(
                builder: (context, offlineModeProvider, child) {
                  // Show sync option only if offline mode is disabled
                  if (!offlineModeProvider.isOfflineModeEnabled) {
                    return _settingsOption(
                      title: LocaleKeys.DataSyncTitle.tr(),
                      subtitle: LocaleKeys.DataSyncDescription.tr(),
                      icon: Icons.cloud_sync,
                      onTap: () {
                        _showSyncDialog(context);
                      },
                    );
                  } else {
                    // Return empty widget when offline mode is enabled
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
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

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SyncDialog(),
    );
  }
}

class _SyncDialog extends StatefulWidget {
  @override
  _SyncDialogState createState() => _SyncDialogState();
}

class _SyncDialogState extends State<_SyncDialog> {
  final SyncManager _syncManager = SyncManager();
  bool _isSyncing = false;
  String _statusMessage = '';
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = await _syncManager.getLastSyncTime();
    setState(() {
      _lastSyncTime = lastSync;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.DataSyncTitle.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.DataSyncDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            if (_lastSyncTime != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.text.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(
                    '${LocaleKeys.LastSync.tr()}: ${DateFormat('dd.MM.yyyy HH:mm').format(_lastSyncTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isSyncing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.info,
                        size: 16,
                        color: AppColors.main,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Sync Button (tek buton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncData,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? LocaleKeys.SyncInProgress.tr() : LocaleKeys.SyncNow.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.SyncNote.tr(),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.Close.tr()),
        ),
      ],
    );
  }

  Future<void> _syncData() async {
    // Check if offline mode is enabled
    if (OfflineModeProvider().shouldDisableFirebase()) {
      setState(() {
        _statusMessage = LocaleKeys.OfflineModeSyncDisabled.tr();
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _statusMessage = LocaleKeys.SyncingData.tr();
    });

    try {
      // Önce local verileri upload et, sonra güncellemeleri download et
      final uploadSuccess = await _syncManager.performFullUpload();
      final downloadSuccess = await _syncManager.performFullDownload();

      final allSuccess = uploadSuccess && downloadSuccess;

      setState(() {
        _isSyncing = false;
        _statusMessage = allSuccess ? LocaleKeys.SyncSuccess.tr() : LocaleKeys.SyncError.tr();
      });

      if (allSuccess) {
        await _loadLastSyncTime();
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _statusMessage = 'SyncErrorWithMessage'.tr(args: [e.toString()]);
      });
    }
  }
}
