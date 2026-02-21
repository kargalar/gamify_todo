import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class DisciplineInfoDialog extends StatelessWidget {
  const DisciplineInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final dp = context.read<UserProvider>().disciplinePoints;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.DisciplineSystem.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      LocaleKeys.CurrentDP.tr(args: [dp.toString()]),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rules Title
          Text(
            LocaleKeys.HowToEarnDP.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Rule items
          _buildRuleItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: LocaleKeys.CompletedTaskOrRoutine.tr(),
            points: '+1 ${LocaleKeys.DisciplinePoints.tr()}',
            pointsColor: Colors.green,
          ),
          _buildRuleItem(
            icon: Icons.star_border,
            iconColor: Colors.orange,
            title: LocaleKeys.CompletedAllTasks.tr(),
            points: '+2 ${LocaleKeys.DisciplinePoints.tr()}',
            pointsColor: Colors.orange,
          ),
          _buildRuleItem(
            icon: Icons.workspace_premium_outlined,
            iconColor: Colors.amber,
            title: LocaleKeys.CompletedAllRoutines.tr(),
            points: '+5 ${LocaleKeys.DisciplinePoints.tr()}',
            pointsColor: Colors.amber,
          ),

          const SizedBox(height: 20),
          Text(
            LocaleKeys.HowToLoseDP.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildRuleItem(
            icon: Icons.cancel_outlined,
            iconColor: Colors.red,
            title: LocaleKeys.FailedTaskOrRoutine.tr(),
            points: '-1 ${LocaleKeys.DisciplinePoints.tr()}',
            pointsColor: Colors.red,
          ),

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                LocaleKeys.GotIt.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String points,
    required Color pointsColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pointsColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              points,
              style: TextStyle(
                color: pointsColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
