import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/3%20Page/Home/Add%20Task/add_task_page.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/all_time_stats_widget.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/recent_logs_widget.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/success_metrics_widget.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/trait_progress_widget.dart';
import 'package:gamify_todo/5%20Service/locale_keys.g.dart';
import 'package:gamify_todo/5%20Service/navigator_service.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class RoutineDetailPage extends StatefulWidget {
  const RoutineDetailPage({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late TaskDetailViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    context.watch<TaskProvider>();

    //? burayı her sainye çalıştırarak (yukarıda watch sayesinde) sayfadaki istatistikleri canlı bir şekilde gösteriyorum. timer aktif iseveya galiba herhangi bir düzenleme yapıldığında. lakin performan sorunu olur mu. sanmıyorum.
    _viewModel = TaskDetailViewModel(widget.taskModel);
    _viewModel.initialize();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskModel.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => NavigatorService().goBack(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NavigatorService().goTo(
                AddTaskPage(editTask: widget.taskModel),
                transition: Transition.rightToLeft,
              );
            },
            child: Text(LocaleKeys.Edit.tr()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current Progress
              EditProgressWidget.forTask(task: widget.taskModel),
              const SizedBox(height: 20),

              // All Time Stats
              AllTimeStatsWidget(
                viewModel: _viewModel,
                taskType: widget.taskModel.type,
              ),
              const SizedBox(height: 20),

              // // Best Performance
              // BestPerformanceWidget(viewModel: _viewModel),
              // const SizedBox(height: 30),

              // Success Metrics
              SuccessMetricsWidget(viewModel: _viewModel),

              // Trait Progress
              TraitProgressWidget(viewModel: _viewModel),
              const SizedBox(height: 20),

              // Recent Logs
              RecentLogsWidget(viewModel: _viewModel),
            ],
          ),
        ),
      ),
    );
  }
}
