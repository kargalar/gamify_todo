import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';

class TaskContributionsWidget extends StatelessWidget {
  final HomeViewModel vm;

  const TaskContributionsWidget({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final taskCount = vm.todayContributions().length;
    // Calculate dynamic max height: header (60) + tasks (50 per task) + padding
    final dynamicMaxHeight = taskCount <= 3 ? 220.0 : 220 + (taskCount * 1.0).clamp(100.0, 400.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: dynamicMaxHeight,
        minHeight: 100,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bugünkü Görevler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(
            child: vm.todayContributions().isEmpty
                ? Center(
                    child: Text(
                      'Bugün henüz görev tamamlanmamış',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: false,
                    physics: const BouncingScrollPhysics(),
                    itemCount: vm.todayContributions().length,
                    itemBuilder: (context, index) {
                      final contribution = vm.todayContributions()[index];
                      final title = contribution['title'] as String;
                      final duration = contribution['duration'] as Duration;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.main.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.main.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.main.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                duration.textShortDynamic(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.main,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
