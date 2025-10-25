import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.filter_list,
        size: 20,
        color: AppColors.text,
      ),
      tooltip: LocaleKeys.Settings.tr(),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(
        borderRadius: AppColors.borderRadiusAll,
      ),
      itemBuilder: (context) {
        final homeViewModel = context.read<HomeViewModel>();
        return [
          PopupMenuItem(
            onTap: () async {
              await context.read<HomeViewModel>().toggleShowCompleted();
            },
            child: Row(
              children: [
                Icon(
                  homeViewModel.showCompleted ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.text,
                ),
                const SizedBox(width: 8),
                Text(
                  "${homeViewModel.showCompleted ? LocaleKeys.Hide.tr() : LocaleKeys.Show.tr()} ${LocaleKeys.Done.tr()}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<HomeViewModel>().skipRoutinesForSelectedDate();
              });
            },
            child: Row(
              children: [
                const Icon(Icons.skip_next, size: 18),
                const SizedBox(width: 8),
                Text(LocaleKeys.SkipRoutine.tr()),
              ],
            ),
          ),
        ];
      },
    );
  }
}
