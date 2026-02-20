import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_task_list_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class TraitRelatedTasksSection extends StatefulWidget {
  final List<TaskModel> relatedTasks;
  final List<TaskModel> relatedRoutines;
  final Duration Function(TaskModel) calculateTaskDuration;
  final Color selectedColor;

  const TraitRelatedTasksSection({
    super.key,
    required this.relatedTasks,
    required this.relatedRoutines,
    required this.calculateTaskDuration,
    required this.selectedColor,
  });

  @override
  State<TraitRelatedTasksSection> createState() => _TraitRelatedTasksSectionState();
}

class _TraitRelatedTasksSectionState extends State<TraitRelatedTasksSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panelBackground2.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.selectedColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: widget.selectedColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.text.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab Bar Custom Container
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.panelBackground2,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.selectedColor,
              boxShadow: [
                BoxShadow(
                  color: widget.selectedColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.text.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt, size: 18),
                    const SizedBox(width: 8),
                    Text(LocaleKeys.RelatedTasks.tr()),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 18),
                    SizedBox(width: 8),
                    Text("Related Routines"),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tab Views (Using AnimatedSwitcher for smooth transitions without height issues)
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final isTasksTab = _tabController.index == 0;

            if (isTasksTab) {
              return widget.relatedTasks.isEmpty
                  ? _buildEmptyState(LocaleKeys.NoTasksWithProgressFound.tr())
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.relatedTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = widget.relatedTasks[index];
                        final duration = widget.calculateTaskDuration(task);
                        return TraitTaskListItem(
                          task: task,
                          taskDuration: duration,
                          isRoutine: false,
                        );
                      },
                    );
            } else {
              return widget.relatedRoutines.isEmpty
                  ? _buildEmptyState("No routines with progress found")
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.relatedRoutines.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final routine = widget.relatedRoutines[index];
                        final duration = widget.calculateTaskDuration(routine);
                        return TraitTaskListItem(
                          task: routine,
                          taskDuration: duration,
                          isRoutine: true,
                        );
                      },
                    );
            }
          },
        ),
      ],
    );
  }
}
