import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/auth_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Page/Settings/settings_page.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class ProfilePageTopSection extends StatefulWidget {
  const ProfilePageTopSection({
    super.key,
  });

  @override
  State<ProfilePageTopSection> createState() => _ProfilePageTopSectionState();
}

class _ProfilePageTopSectionState extends State<ProfilePageTopSection> {
  // compute durations on demand in build to keep UI fresh

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Debug loginUser
        debugPrint('ProfilePageTopSection: StreamBuilder called');
        debugPrint('ProfilePageTopSection: Firebase user = ${snapshot.data?.email}');
        debugPrint('ProfilePageTopSection: loginUser = ${loginUser?.username}');
        debugPrint('ProfilePageTopSection: loginUser email = ${loginUser?.email}');
        debugPrint('ProfilePageTopSection: loginUser id = ${loginUser?.id}');

        return _buildProfileContent();
      },
    );
  }

  Widget _buildProfileContent() {
    // compute total duration from tasks (keeps updated)
    final Duration totalDuration = TaskProvider().taskList.fold(
      Duration.zero,
      (previousValue, element) {
        if (element.remainingDuration != null) {
          if (element.type == TaskTypeEnum.CHECKBOX && element.status != TaskStatusEnum.DONE) {
            return previousValue;
          }
          return previousValue +
              (element.type == TaskTypeEnum.CHECKBOX
                  ? element.remainingDuration!
                  : element.type == TaskTypeEnum.COUNTER
                      ? element.remainingDuration! * element.currentCount!
                      : element.currentDuration!);
        }
        return previousValue;
      },
    );

    // Sleeker banner with subtle gradient and rounded bottom
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withAlpha(220), Theme.of(context).primaryColor.withAlpha(120)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with subtle ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                  gradient: LinearGradient(
                    colors: [Colors.white.withAlpha(30), Theme.of(context).primaryColor.withAlpha(40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loginUser?.username ?? '—',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await NavigatorService().goTo(const SettingsPage());
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ],
                    ),
                    if (loginUser?.email != null && loginUser!.email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        loginUser!.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // subtle progress bar showing total hours as a visual cue
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${totalDuration.toLevel()} • ${TaskProvider().taskList.length} ${LocaleKeys.Tasks.tr()}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (totalDuration.inHours / 20).clamp(0, 1).toDouble(),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
