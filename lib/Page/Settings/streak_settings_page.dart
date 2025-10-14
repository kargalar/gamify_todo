import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../General/app_colors.dart';
import 'package:next_level/generated/lib/Service/locale_keys.g.dart';
import 'view_model/streak_settings_view_model.dart';

class StreakSettingsPage extends StatefulWidget {
  const StreakSettingsPage({super.key});

  @override
  State<StreakSettingsPage> createState() => _StreakSettingsPageState();
}

class _StreakSettingsPageState extends State<StreakSettingsPage> with TickerProviderStateMixin {
  late StreakSettingsViewModel _viewModel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = StreakSettingsViewModel();
    _viewModel.initialize();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer<StreakSettingsViewModel>(
                  builder: (context, viewModel, child) {
                    if (!viewModel.isInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildBody(viewModel);
                  },
                ),
              ),
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        LocaleKeys.StreakSettings.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.appbar,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.panelBackground.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 16,
            color: AppColors.text,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody(StreakSettingsViewModel viewModel) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildMinimumHoursSection(viewModel),
          const SizedBox(height: 24),
          _buildVacationDaysSection(viewModel),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.main.withValues(alpha: 0.1),
            AppColors.main.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.main.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.main,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.StreakSettings.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.StreakMinimumHoursDesc.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimumHoursSection(StreakSettingsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.MinimumHoursForStreak.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: viewModel.hoursError != null ? AppColors.red.withValues(alpha: 0.5) : AppColors.text.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: viewModel.hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                labelText: LocaleKeys.Hours.tr(),
                suffixText: LocaleKeys.Hours.tr().toLowerCase(),
                suffixStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                errorText: viewModel.hoursError,
                errorStyle: const TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                ),
                labelStyle: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              onChanged: viewModel.onHoursChanged,
            ),
          ),
          if (viewModel.hoursError == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.main,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Current setting: ${viewModel.getFormattedHours()} hours per day",
                      style: TextStyle(
                        color: AppColors.main,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVacationDaysSection(StreakSettingsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.beach_access_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.VacationDays.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.SelectWeekdaysForVacation.tr(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          _buildWeekdaySelector(viewModel),
          if (viewModel.streakSettings.vacationWeekdays.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.main,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${viewModel.streakSettings.vacationWeekdays.length} vacation day(s) selected",
                      style: TextStyle(
                        color: AppColors.main,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector(StreakSettingsViewModel viewModel) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(7, (index) {
        final isSelected = viewModel.isWeekdaySelected(index);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: () => viewModel.toggleVacationWeekday(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.main : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.main.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                viewModel.weekdayNames[index],
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.text,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.HowItWorks.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.timer_outlined,
            title: LocaleKeys.MinimumHours.tr(),
            description: LocaleKeys.MinimumHoursDesc.tr(),
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.event_busy_outlined,
            title: LocaleKeys.VacationDays.tr(),
            description: LocaleKeys.VacationDaysDesc.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.text.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<StreakSettingsViewModel>(
      builder: (context, viewModel, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showResetDialog(viewModel),
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.white,
          ),
          label: const Text(
            "Reset to Defaults",
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  void _showResetDialog(StreakSettingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: AppColors.red,
              size: 24,
            ),
            SizedBox(width: 12),
            Text("Reset Settings"),
          ],
        ),
        content: const Text(
          "Are you sure you want to reset all streak settings to default values?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocaleKeys.Cancel.tr(),
              style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.resetToDefaults();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}
