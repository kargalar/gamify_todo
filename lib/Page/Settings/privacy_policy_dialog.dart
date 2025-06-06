import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.PrivacyPolicy.tr()),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Data Collection"),
              _sectionContent("We collect data that you provide directly to us, such as when you create an account, "
                  "add tasks, or contact us for support. This includes your task data, preferences, and usage patterns."),
              const SizedBox(height: 16),
              _sectionTitle("Data Usage"),
              _sectionContent("We use your data to provide and improve our service, including:\n"
                  "• Storing and syncing your tasks across devices\n"
                  "• Analyzing usage patterns to improve app functionality\n"
                  "• Providing customer support\n"
                  "• Sending notifications about your tasks"),
              const SizedBox(height: 16),
              _sectionTitle("Data Storage"),
              _sectionContent("Your data is stored locally on your device and can be backed up to your cloud storage if you choose. "
                  "We do not store your personal data on our servers unless you explicitly opt-in to cloud sync features."),
              const SizedBox(height: 16),
              _sectionTitle("Data Sharing"),
              _sectionContent("We do not sell, trade, or otherwise transfer your personal data to third parties without your consent, "
                  "except as described in this privacy policy or as required by law."),
              const SizedBox(height: 16),
              _sectionTitle("Your Rights"),
              _sectionContent("You have the right to:\n"
                  "• Access your personal data\n"
                  "• Correct inaccurate data\n"
                  "• Delete your data\n"
                  "• Export your data\n"
                  "• Opt-out of data collection"),
              const SizedBox(height: 16),
              _sectionTitle("Contact Us"),
              _sectionContent("If you have any questions about this privacy policy, please contact us at privacy@gamifytodo.com"),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: AppColors.borderRadiusAll,
                onTap: () async {
                  final Uri url = Uri.parse('https://www.gamifytodo.com/privacy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    await Clipboard.setData(
                      const ClipboardData(text: 'https://www.gamifytodo.com/privacy'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Privacy policy URL copied to clipboard'),
                          backgroundColor: AppColors.main,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.main.withAlpha(51),
                    borderRadius: AppColors.borderRadiusAll,
                    border: Border.all(
                      color: AppColors.main,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        color: AppColors.main,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Read Full Privacy Policy Online",
                        style: TextStyle(
                          color: AppColors.main,
                          fontWeight: FontWeight.bold,
                        ),
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
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.main,
      ),
    );
  }

  Widget _sectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.text,
        height: 1.4,
      ),
    );
  }
}
