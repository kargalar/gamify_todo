import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/task_name.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';
import 'package:next_level/Page/Store/Widget/set_credit.dart';
import 'package:next_level/Widgets/Common/recent_logs_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:provider/provider.dart';

class AddStoreItemPage extends StatefulWidget {
  const AddStoreItemPage({
    super.key,
    this.editItemModel,
  });

  final ItemModel? editItemModel;

  @override
  State<AddStoreItemPage> createState() => _AddStoreItemPageState();
}

class _AddStoreItemPageState extends State<AddStoreItemPage> with WidgetsBindingObserver {
  late final addStoreItemProvider = context.read<AddStoreItemProvider>();
  late final storeProvider = context.read<StoreProvider>();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        addStoreItemProvider.setEditItem(widget.editItemModel);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AddStoreItemPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editItemModel != oldWidget.editItemModel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          addStoreItemProvider.setEditItem(widget.editItemModel);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Uygulama arka plana alındığında veya inactive olduğunda timer'ı durdur
      if (addStoreItemProvider.isDescriptionTimerActive) {
        addStoreItemProvider.pauseDescriptionTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar aktif olduğunda, eğer description focus'taysa timer'ı başlat
      if (addStoreItemProvider.descriptionFocus.hasFocus && !addStoreItemProvider.isDescriptionTimerActive) {
        addStoreItemProvider.startDescriptionTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBackCheck();
      },
      child: GestureDetector(
        // Unfocus when tapping outside of text fields
        onTap: () {
          // Unfocus all text fields
          addStoreItemProvider.unfocusAll();
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.editItemModel != null ? LocaleKeys.EditItem.tr() : LocaleKeys.AddItem.tr()),
            leading: InkWell(
              borderRadius: AppColors.borderRadiusAll,
              onTap: () {
                // Unfocus before going back
                addStoreItemProvider.unfocusAll();
                FocusScope.of(context).unfocus();
                goBackCheck();
              },
              child: const Icon(Icons.arrow_back_ios),
            ),
            actions: [
              if (widget.editItemModel == null)
                TextButton(
                  onPressed: () {
                    // Unfocus before saving
                    addStoreItemProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    addItem();
                  },
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Reset store item progress menu (only for edit mode)
              if (widget.editItemModel != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset_item_progress') {
                      _showResetItemProgressDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'reset_item_progress',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.ResetStoreProgress.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            // Add keyboard dismiss behavior
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (widget.editItemModel != null) ...[
                    // Current Progress Container
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with title and icon
                          Row(
                            children: [
                              Icon(
                                Icons.track_changes_rounded,
                                color: AppColors.main,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Current Progress",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: AppColors.text.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ), // Progress Widget
                          EditProgressWidget.forStoreItem(
                            item: widget.editItemModel!,
                            onProgressChanged: () => setState(() {}), // Real-time UI güncelleme
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ], // Item name
                  TaskName(
                    isStore: true,
                    autoFocus: widget.editItemModel == null,
                    onTaskSubmit: null, // Store items don't need this functionality
                  ),
                  const SizedBox(height: 10),

                  // Credit section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: const Row(
                      children: [
                        Text(
                          "Cost",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        SetCredit(),
                      ],
                    ),
                  ),

                  if (widget.editItemModel == null) ...[
                    const SizedBox(height: 10),
                    // Type section
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const SelectTaskType(isStore: true),
                    ),
                  ],

                  // Duration section - only show if not counter type
                  Consumer<AddStoreItemProvider>(
                    builder: (context, provider, child) {
                      final selectedType = provider.selectedTaskType;
                      if (selectedType == TaskTypeEnum.COUNTER) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.panelBackground,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const DurationPickerWidget(isStore: true),
                          ),
                        ],
                      );
                    },
                  ),

                  // Recent Logs Container
                  if (widget.editItemModel != null) ...[
                    const SizedBox(height: 10),
                    RecentLogsWidget(
                      storeItemId: widget.editItemModel!.id,
                      storeItemType: widget.editItemModel!.type,
                      onLogUpdated: () => setState(() {}),
                    ),
                    const SizedBox(height: 5),
                  ],

                  // Delete button for edit mode
                  if (widget.editItemModel != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: InkWell(
                        borderRadius: AppColors.borderRadiusAll,
                        onTap: () {
                          // Unfocus before showing dialog
                          addStoreItemProvider.unfocusAll();
                          FocusScope.of(context).unfocus();

                          Helper().getDialog(
                            message: "Are you sure you want to delete this item?",
                            onAccept: () {
                              storeProvider.deleteItem(widget.editItemModel!.id);
                              NavigatorService().goBackNavbar();
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: AppColors.borderRadiusAll,
                            color: AppColors.red,
                          ),
                          child: Text(
                            LocaleKeys.Delete.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void addItem() {
    if (addStoreItemProvider.taskNameController.text.trim().isEmpty) {
      addStoreItemProvider.taskNameController.clear();

      Helper().getMessage(
        message: LocaleKeys.NameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    if (isLoading) return;
    isLoading = true;

    addStoreItemProvider.addItem();
    NavigatorService().goBackNavbar();
  }

  void goBackCheck() {
    if (widget.editItemModel != null) {
      if (addStoreItemProvider.taskNameController.text.trim().isEmpty) {
        addStoreItemProvider.taskNameController.clear();

        Helper().getMessage(
          message: LocaleKeys.NameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      if (isLoading) return;
      isLoading = true;

      addStoreItemProvider.updateItem(widget.editItemModel!);
      NavigatorService().back();
    } else {
      NavigatorService().back();
    }
  }

  void _showResetItemProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetStoreProgress.tr()),
          content: Text(LocaleKeys.ResetStoreProgressWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetSingleItemProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetSingleItemProgress() async {
    try {
      if (widget.editItemModel == null) return;

      final item = widget.editItemModel!;

      // Reset progress values
      if (item.type == TaskTypeEnum.COUNTER) {
        item.currentCount = 0;
      } else if (item.type == TaskTypeEnum.TIMER) {
        item.currentDuration = Duration.zero;
        // Also stop timer if it's active
        if (item.isTimerActive == true) {
          item.isTimerActive = false;
        }
      }

      // Update item in storage
      await HiveService().updateItem(item);

      // Clear logs for this item from TaskProgressViewModel
      final logs = await TaskProgressViewModel.getStoreItemLogs(item.id);
      for (int i = logs.length - 1; i >= 0; i--) {
        TaskProgressViewModel.deleteStoreItemLog(i);
      }

      // Update provider
      storeProvider.setStateItems();

      // Success message
      Helper().getMessage(message: LocaleKeys.ResetStoreProgressSuccess.tr());

      // Refresh the page
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }
}
