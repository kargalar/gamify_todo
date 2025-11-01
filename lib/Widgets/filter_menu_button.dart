import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Home/Widget/home_filter_dialog.dart';

class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({super.key});

  void _showFilterDialog(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => HomeFilterDialog(
        showRoutines: homeViewModel.showRoutines,
        showTasks: homeViewModel.showTasks,
        showTodayTasks: homeViewModel.showTodayTasks,
        dateFilterState: homeViewModel.dateFilterState,
        selectedTaskTypes: homeViewModel.selectedTaskTypes,
        selectedStatuses: homeViewModel.selectedStatuses,
        showEmptyStatus: homeViewModel.showEmptyStatus,
        onFiltersChanged: (showRoutines, showTasks, showTodayTasks, dateFilterState, taskTypes, statuses, showEmpty) {
          homeViewModel.updateFilters(
            showRoutines,
            showTasks,
            showTodayTasks,
            dateFilterState,
            taskTypes,
            statuses,
            showEmpty,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.filter_list,
        size: 20,
        color: AppColors.text,
      ),
      tooltip: LocaleKeys.Filters.tr(),
      onPressed: () => _showFilterDialog(context),
    );
  }
}
