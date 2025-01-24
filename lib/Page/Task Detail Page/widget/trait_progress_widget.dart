import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.attributeBars.isNotEmpty) ...[
            Text(
              LocaleKeys.Attributes.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...viewModel.attributeBars,
            const SizedBox(height: 16),
          ],
          if (viewModel.skillBars.isNotEmpty) ...[
            Text(
              LocaleKeys.Skills.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...viewModel.skillBars,
          ],
        ],
      ),
    );
  }
}
