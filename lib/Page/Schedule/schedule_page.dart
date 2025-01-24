import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:gamify_todo/Page/Schedule/task_calendar_page.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program'),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Haftalık Rutinler'),
            Tab(text: 'Görev Takvimi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WeeklyRoutineView(),
          TaskCalendarPage(),
        ],
      ),
    );
  }
}

class WeeklyRoutineView extends StatelessWidget {
  const WeeklyRoutineView({super.key});

  String _getDurationText(dynamic item) {
    if (item.remainingDuration == null) return 'Belirtilmemiş';

    if (item.type == TaskTypeEnum.COUNTER) {
      final totalMicroseconds = (item.remainingDuration as Duration).inMicroseconds * (item.targetCount as int);
      final totalDuration = Duration(microseconds: totalMicroseconds.toInt());
      return totalDuration.textShort2hour();
    }

    return (item.remainingDuration as Duration).textShort2hour();
  }

  Duration _calculateTotalDuration(List<dynamic> routines) {
    int totalMicroseconds = 0;

    for (var routine in routines) {
      if (routine.remainingDuration != null) {
        if (routine.type == TaskTypeEnum.COUNTER) {
          totalMicroseconds += (routine.remainingDuration as Duration).inMicroseconds * (routine.targetCount as int);
        } else {
          totalMicroseconds += (routine.remainingDuration as Duration).inMicroseconds;
        }
      }
    }

    return Duration(microseconds: totalMicroseconds);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final routines = taskProvider.routineList;
    final weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

    if (routines.isEmpty) {
      return const Center(
        child: Text('Henüz rutin eklenmemiş'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(
          color: AppColors.text.withAlpha(51),
          width: 1,
        ),
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.text.withAlpha(26),
            ),
            children: const [
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Gün',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Rutinler',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Day rows
          ...List.generate(weekDays.length, (index) {
            final dayRoutines = routines.where((routine) => routine.repeatDays.contains(index)).toList();
            final totalDuration = _calculateTotalDuration(dayRoutines);

            return TableRow(
              children: [
                // Day name
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekDays[index],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (dayRoutines.isNotEmpty)
                          Text(
                            'Toplam: ${totalDuration.textShort2hour()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.text.withAlpha(179),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Routines for the day
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dayRoutines
                          .map(
                            (routine) => InkWell(
                              onTap: () async {
                                final routineTask = taskProvider.taskList.firstWhere(
                                  (task) => task.routineID == routine.id,
                                  orElse: () => TaskModel(
                                    title: routine.title,
                                    type: routine.type,
                                    taskDate: DateTime.now(),
                                    isNotificationOn: routine.isNotificationOn,
                                    isAlarmOn: routine.isAlarmOn,
                                    routineID: routine.id,
                                  ),
                                );

                                await NavigatorService().goTo(
                                  RoutineDetailPage(taskModel: routineTask),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.repeat, color: Colors.blue, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(routine.title),
                                          Text(
                                            '${_getDurationText(routine)}${routine.time != null ? ' • ${routine.time!.hour}:${routine.time!.minute.toString().padLeft(2, '0')}' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.text.withAlpha(179),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
