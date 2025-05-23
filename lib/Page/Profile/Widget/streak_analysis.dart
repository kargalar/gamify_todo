import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/profile_view_model.dart';
import 'package:provider/provider.dart';

class StreakAnalysis extends StatelessWidget {
  const StreakAnalysis({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();
    final streaks = viewModel.getStreakAnalysis();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStreakDisplay(LocaleKeys.CurrentStreak.tr(), streaks['currentStreak']!),
            _buildStreakDisplay(LocaleKeys.LongestStreak.tr(), streaks['longestStreak']!),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakDisplay(String label, int days) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '$days ${LocaleKeys.Day.tr()}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
