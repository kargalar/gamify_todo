import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/auth_service.dart';

class ProfilePageTopSection extends StatefulWidget {
  const ProfilePageTopSection({
    super.key,
  });

  @override
  State<ProfilePageTopSection> createState() => _ProfilePageTopSectionState();
}

class _ProfilePageTopSectionState extends State<ProfilePageTopSection> {
  late Duration totalDuration;

  @override
  void initState() {
    super.initState();
    _calculateTotalDuration();
  }

  void _calculateTotalDuration() {
    // ? her açıldığında tüm taskalrdan çekmek yerine direkt uygulama açılırken bir defa hesaplayıp bir değişkene atayıp gerisini oradan güncellemek iyi olur mu bilmiyorum. 1500 task olduğunda nasıl oalcak bundan şüpheliyim. galiba bir cache yapısı da kurmak lazım
    totalDuration = TaskProvider().taskList.fold(
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
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info section
        Row(
          children: [
            // Avatar placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(150),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 30,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            // User name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loginUser?.username ?? 'Null',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (loginUser?.email != null && loginUser!.email.isNotEmpty)
                    Text(
                      loginUser!.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Stats section
        Row(
          children: [
            Column(
              children: [
                Text(
                  totalDuration.toLevel(),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  totalDuration.textShort2hour(),
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            // const Spacer(),
            // const Text(
            //   // TODO: karma eklenince gelecek
            //   'Karma -57',
            //   style: TextStyle(
            //     fontSize: 18,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
