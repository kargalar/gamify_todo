import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// import 'package:next_level/Core/Widgets/language_pop.dart'; // Temporarily disabled
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Settings/color_selection_dialog.dart';
import 'package:next_level/Page/Settings/contact_us_dialog.dart';
import 'package:next_level/Page/Settings/file_storage_management_page.dart';
import 'package:next_level/Page/Settings/navbar_customization_page.dart';
import 'package:next_level/Page/Settings/privacy_policy_webview_page.dart';
import 'package:next_level/Page/Settings/task_style_selection_dialog.dart';
import 'package:next_level/Page/Settings/alarm_sound_selection_dialog.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/app_launch_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:next_level/Service/logging_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    LogService.debug('Settings Page: Initialized');
  }

  Future<void> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
      LogService.debug('Settings: App version loaded successfully: $_appVersion');
    } catch (e) {
      LogService.error('Settings: Error loading app version: $e');
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ColorProvider changes to rebuild the page
    context.watch<ColorProvider>();
    LogService.debug('Settings Page: Rebuilding UI due to color change');

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
            // Language selection temporarily disabled - default is English
            // _settingsOption(
            //   title: LocaleKeys.SelectLanguage.tr(),
            //   icon: Icons.language,
            //   onTap: () {
            //     showDialog(
            //       context: context,
            //       builder: (context) => const LanguageSelectionPopup(),
            //     );
            //   },
            // ),
            // _settingsOption(
            //   title: LocaleKeys.ThemeSelection.tr(),
            //   subtitle: LocaleKeys.ThemeSelectionSubtitle.tr(),
            //   icon: Icons.dark_mode,
            //   onTap: () {
            //     context.read<ThemeProvider>().changeTheme();
            //   },
            //   trailing: Switch.adaptive(
            //     value: AppColors.isDark,
            //     thumbIcon: AppColors.isDark
            //         ? WidgetStateProperty.all(
            //             const Icon(
            //               Icons.brightness_2,
            //               color: AppColors.black,
            //             ),
            //           )
            //         : WidgetStateProperty.all(
            //             const Icon(
            //               Icons.wb_sunny,
            //               color: AppColors.white,
            //             ),
            //           ),
            //     trackOutlineColor: AppColors.isDark ? WidgetStateProperty.all(AppColors.transparent) : WidgetStateProperty.all(AppColors.dirtyRed),
            //     inactiveThumbColor: AppColors.dirtyRed,
            //     inactiveTrackColor: AppColors.white,
            //     onChanged: (_) {
            //       context.read<ThemeProvider>().changeTheme();
            //     },
            //   ),
            // ),
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
            _settingsOption(
              title: 'Alarm Sound Selection',
              subtitle: 'Configure alarm sounds for different task types',
              icon: Icons.music_note,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AlarmSoundSelectionDialog(),
                );
                LogService.debug('Settings: Alarm sound dialog closed');
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
            // Navbar Customization option
            _settingsOption(
              title: LocaleKeys.NavbarCustomization.tr(),
              subtitle: LocaleKeys.NavbarCustomizationSubtitle.tr(),
              icon: Icons.view_carousel,
              onTap: () {
                NavigatorService().goTo(const NavbarCustomizationPage());
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
              onTap: () async {
                const url = 'https://kargalar.github.io/nextlevel_privacy2/';
                LogService.debug('Settings: Opening Privacy Policy');

                // Check if webview is supported on this platform
                if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || kIsWeb) {
                  LogService.debug('Settings: Using WebView for Privacy Policy');
                  NavigatorService().goTo(const PrivacyPolicyWebViewPage());
                } else {
                  // For unsupported platforms (like Windows), use external browser
                  LogService.debug('Settings: Using external browser for Privacy Policy: $url');
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    LogService.debug('Settings: Privacy Policy URL launched successfully');
                  } else {
                    LogService.error('Settings: Could not launch Privacy Policy URL');
                  }
                }
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

            // Development mode: Review test button
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Developer Options',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _settingsOption(
                title: 'Test App Review',
                subtitle: 'Reset all review data and test system',
                icon: Icons.bug_report,
                color: AppColors.dirtyRed,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  await appLaunchService.resetLaunchCount();
                  final count = await appLaunchService.getLaunchCount();
                  LogService.debug('Settings: All review data reset, launch count: $count');

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review data reset! Restart app to test.\nWill ask at: 5, 20, 40, 60 launches.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              _settingsOption(
                title: 'Show Launch Info',
                subtitle: 'Display current app launch and review status',
                icon: Icons.info_outline,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  final count = await appLaunchService.getLaunchCount();
                  final lastReviewRequest = await appLaunchService.getLastReviewRequestCount();
                  final reviewCompleted = await appLaunchService.isReviewCompleted();
                  final thresholds = appLaunchService.getReviewThresholds();

                  LogService.debug('Settings: Count: $count, Last request: $lastReviewRequest, Completed: $reviewCompleted');

                  // Sonraki eşiği hesapla
                  int? nextThreshold;
                  for (int threshold in thresholds) {
                    if (count < threshold) {
                      nextThreshold = threshold;
                      break;
                    }
                  }

                  if (mounted) {
                    showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Launch & Review Info'),
                        content: Text(
                          'Current launch count: $count\n'
                          'Last review request at: ${lastReviewRequest > 0 ? lastReviewRequest : "None"}\n'
                          'Review completed: ${reviewCompleted ? "Yes" : "No"}\n'
                          'Next review at: ${nextThreshold ?? "No more"}\n'
                          '\nThresholds: ${thresholds.join(", ")}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              _settingsOption(
                title: 'Mark Review as Completed',
                subtitle: 'Tell app you have reviewed (stops asking)',
                icon: Icons.check_circle_outline,
                color: AppColors.deepGreen,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  await appLaunchService.markReviewAsCompleted();
                  LogService.debug('Settings: Review marked as completed');

                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review marked as completed! App will not ask again.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],

            // App Version at the bottom
            const SizedBox(height: 5),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
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
