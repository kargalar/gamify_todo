import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/Enums/status_enum.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:gamify_todo/Page/Home/Add%20Task/Widget/task_name.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/edit_progress_widget.dart';
import 'package:gamify_todo/Page/Store/Widget/set_credit.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Service/navigator_service.dart';
import 'package:gamify_todo/Provider/add_store_item_providerr.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/store_item_model.dart';
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

class _AddStoreItemPageState extends State<AddStoreItemPage> {
  late final addStoreItemProvider = context.read<AddStoreItemProvider>();
  late final storeProvider = context.read<StoreProvider>();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.editItemModel != null) {
      addStoreItemProvider.taskNameController.text = widget.editItemModel!.title;
      addStoreItemProvider.descriptionController.text = widget.editItemModel!.description ?? '';
      addStoreItemProvider.credit = widget.editItemModel!.credit;
      addStoreItemProvider.taskDuration = widget.editItemModel!.addDuration!;
      addStoreItemProvider.selectedTaskType = widget.editItemModel!.type;
      addStoreItemProvider.targetCount = widget.editItemModel!.addCount ?? 1;
    } else {
      addStoreItemProvider.taskNameController.clear();
      addStoreItemProvider.descriptionController.clear();
      addStoreItemProvider.credit = 0;
      addStoreItemProvider.taskDuration = const Duration(hours: 0, minutes: 0);
      addStoreItemProvider.selectedTaskType = TaskTypeEnum.COUNTER;
      addStoreItemProvider.targetCount = 1;
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
                  if (widget.editItemModel != null) EditProgressWidget.forStoreItem(item: widget.editItemModel!),
                  const SizedBox(height: 10),

                  // Item name
                  TaskName(
                    isStore: true,
                    autoFocus: widget.editItemModel == null,
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
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Credit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        SetCredit(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Duration section
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
                    child: widget.editItemModel == null
                        ? const SelectTaskType(isStore: true)
                        : widget.editItemModel!.type == TaskTypeEnum.COUNTER
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: SelectTargetCount(isStore: true),
                              )
                            : const SizedBox(),
                  ),

                  const SizedBox(height: 5),

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
}
