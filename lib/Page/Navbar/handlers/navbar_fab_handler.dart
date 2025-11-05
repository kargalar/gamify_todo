import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_task_bottom_sheet.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Widgets/add_edit_item_bottom_sheet.dart';
import 'package:get/get.dart';

class NavbarFABHandler {
  final BuildContext context;

  NavbarFABHandler(this.context);

  /// Build FAB based on current tab
  Widget buildFAB(int currentIndex) {
    if (!_shouldShowFAB(currentIndex)) {
      return const SizedBox();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (currentIndex == 1) _buildQuickAddFAB(),
        if (currentIndex == 1) const SizedBox(width: 10),
        _buildMainFAB(currentIndex),
      ],
    );
  }

  /// Check if FAB should be shown for current tab
  bool _shouldShowFAB(int currentIndex) {
    return currentIndex == 0 || currentIndex == 1 || currentIndex == 2 || currentIndex == 3 || currentIndex == 4;
  }

  /// Build quick add FAB for Home tab
  Widget _buildQuickAddFAB() {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        backgroundColor: AppColors.text,
        foregroundColor: AppColors.background,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => const QuickAddTaskBottomSheet(),
          );
        },
        elevation: 4,
        child: const Icon(
          Icons.flash_on_rounded,
          size: 22,
        ),
      ),
    );
  }

  /// Build main FAB with action based on tab
  Widget _buildMainFAB(int currentIndex) {
    return FloatingActionButton(
      backgroundColor: AppColors.text,
      foregroundColor: AppColors.background,
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      onPressed: () => _handleFABPress(currentIndex),
      child: const Icon(
        Icons.add,
        size: 28.0,
      ),
    );
  }

  /// Handle FAB press based on current tab
  Future<void> _handleFABPress(int currentIndex) async {
    switch (currentIndex) {
      case 0:
        // Store tab
        await NavigatorService().goTo(
          const AddStoreItemPage(),
          transition: Transition.downToUp,
        );
        break;
      case 1:
      case 2:
        // Home or Inbox tab
        await NavigatorService().goTo(
          const AddTaskPage(),
          transition: Transition.downToUp,
        );
        break;
      case 3:
        // Notes tab
        _showAddItemBottomSheet(ItemType.note);
        break;
      case 4:
        // Projects tab
        _showAddItemBottomSheet(ItemType.project);
        break;
    }
  }

  /// Show add/edit item bottom sheet
  void _showAddItemBottomSheet(ItemType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditItemBottomSheet(type: type),
    );
  }
}
