import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsDialog extends StatelessWidget {
  const ContactUsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.ContactUs.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _contactOption(
            icon: Icons.email,
            title: LocaleKeys.Email.tr(),
            subtitle: "gamifytodo@gmail.com",
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'gamifytodo@gmail.com',
                queryParameters: {
                  'subject': 'Gamify Todo App Support',
                },
              );
              LogService.debug('ContactUsDialog: Opening email client');
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
                LogService.debug('ContactUsDialog: Email client opened successfully');
              } else {
                LogService.error('ContactUsDialog: Could not open email client');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cannot open email client. Please contact: gamifytodo@gmail.com'),
                      backgroundColor: AppColors.main,
                    ),
                  );
                }
              }
            },
          ),
          // const SizedBox(height: 8),
          // _contactOption(
          //   icon: Icons.web,
          //   title: LocaleKeys.Website.tr(),
          //   subtitle: "www.gamifytodo.com",
          //   onTap: () async {
          //     final Uri url = Uri.parse('https://www.gamifytodo.com');
          //     if (await canLaunchUrl(url)) {
          //       await launchUrl(url, mode: LaunchMode.externalApplication);
          //     } else {
          //       await Clipboard.setData(
          //         const ClipboardData(text: 'www.gamifytodo.com'),
          //       );
          //       if (context.mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: const Text('Website URL copied to clipboard'),
          //             backgroundColor: AppColors.main,
          //           ),
          //         );
          //       }
          //     }
          //   },
          // ),
          const SizedBox(height: 8),
          _contactOption(
            icon: Icons.bug_report,
            title: LocaleKeys.ReportBug.tr(),
            subtitle: LocaleKeys.SendUsBugReports.tr(),
            onTap: () async {
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'gamifytodo@gmail.com',
                queryParameters: {
                  'subject': 'Bug Report - Gamify Todo App',
                  'body': 'Please describe the bug you encountered:\n\n'
                      'Steps to reproduce:\n'
                      '1. \n'
                      '2. \n'
                      '3. \n\n'
                      'Expected behavior:\n\n'
                      'Actual behavior:\n\n'
                      'Device information:\n'
                      '- Operating System: \n'
                      '- App Version: \n',
                },
              );
              LogService.debug('ContactUsDialog: Opening email client for bug report');
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
                LogService.debug('ContactUsDialog: Bug report email client opened successfully');
              } else {
                LogService.error('ContactUsDialog: Could not open email client for bug report');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cannot open email client. Please contact: gamifytodo@gmail.com'),
                      backgroundColor: AppColors.main,
                    ),
                  );
                }
              }
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

  Widget _contactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: AppColors.borderRadiusAll,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.main,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.text.withAlpha(128),
            ),
          ],
        ),
      ),
    );
  }
}
