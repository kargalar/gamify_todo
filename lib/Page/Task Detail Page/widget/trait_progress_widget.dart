import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';

class TraitProgressWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const TraitProgressWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasTraits) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attributes Section
          if (viewModel.attributeBars.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Attributes.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTraitGrid(viewModel.attributeBars),
            const SizedBox(height: 16),
          ],

          // Skills Section
          if (viewModel.skillBars.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Skills.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTraitGrid(viewModel.skillBars),
          ],
        ],
      ),
    );
  }

  Widget _buildTraitGrid(List<Widget> traitBars) {
    // If there's only one trait, don't use a grid
    if (traitBars.length == 1) {
      return traitBars.first;
    }

    // Create a grid layout for multiple traits
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: traitBars.length,
      itemBuilder: (context, index) => traitBars[index],
    );
  }
}
