import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:provider/provider.dart';

/// Arşivlenmiş rutinleri gösteren sayfa
class ArchivedRoutinesPage extends StatelessWidget {
  const ArchivedRoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get all archived routines
    final archivedRoutines = taskProvider.getAllTasks().where((task) {
      final isRoutine = task.routineID != null;
      final isArchived = task.status == TaskStatusEnum.ARCHIVED;
      return isRoutine && isArchived;
    }).toList();

    debugPrint('📦 ArchivedRoutinesPage: Found ${archivedRoutines.length} archived routines');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Arşivlenmiş Rutinler'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: archivedRoutines.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: archivedRoutines.length,
              itemBuilder: (context, index) {
                return TaskItem(
                  taskModel: archivedRoutines[index],
                  key: ValueKey(archivedRoutines[index].id),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: AppColors.text.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Arşivlenmiş Rutin Yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arşivlediğiniz rutinler burada görünecek',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
