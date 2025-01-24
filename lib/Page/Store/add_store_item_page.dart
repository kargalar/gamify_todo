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
import 'package:get/route_manager.dart';
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

  @override
  void initState() {
    super.initState();

    if (widget.editItemModel != null) {
      addStoreItemProvider.taskNameController.text = widget.editItemModel!.title;
      addStoreItemProvider.credit = widget.editItemModel!.credit;
      addStoreItemProvider.taskDuration = widget.editItemModel!.addDuration!;
      addStoreItemProvider.selectedTaskType = widget.editItemModel!.type;
    } else {
      addStoreItemProvider.taskNameController.clear();
      addStoreItemProvider.credit = 0;
      addStoreItemProvider.taskDuration = const Duration(hours: 0, minutes: 0);
      addStoreItemProvider.selectedTaskType = TaskTypeEnum.COUNTER;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBackCheck();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.AddItem.tr()),
          leading: InkWell(
            borderRadius: AppColors.borderRadiusAll,
            onTap: () {
              goBackCheck();
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          actions: [
            if (widget.editItemModel == null)
              Consumer(
                builder: (context, AddStoreItemProvider addStoreItemProvider, child) {
                  return InkWell(
                    borderRadius: AppColors.borderRadiusAll,
                    onTap: () {
                      // TODO: ardarda basıp yanlış kopyalar ekleyebiliyorum düzelt. bir kere basınca tekrar basılamasın tüm sayfaya olabilir.

                      if (addStoreItemProvider.taskNameController.text.trim().isEmpty) {
                        addStoreItemProvider.taskNameController.clear();

                        Helper().getMessage(
                          message: LocaleKeys.NameEmpty.tr(),
                          status: StatusEnum.WARNING,
                        );
                        return;
                      }

                      addStoreItemProvider.addItem();

                      Get.back();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Icon(Icons.check),
                    ),
                  );
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (widget.editItemModel != null) EditProgressWidget.forStoreItem(item: widget.editItemModel!),
                const SizedBox(height: 20),
                TaskName(
                  isStore: true,
                  autoFocus: widget.editItemModel == null,
                ),
                const SizedBox(height: 10),
                const SetCredit(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DurationPickerWidget(isStore: true),
                    const SizedBox(width: 20),
                    if (widget.editItemModel == null) const SelectTaskType(isStore: true),
                    if (widget.editItemModel != null && widget.editItemModel!.type == TaskTypeEnum.COUNTER)
                      const Column(
                        children: [
                          // TODO: localization
                          Text("Add Count"),
                          SelectTargetCount(isStore: true),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.editItemModel != null) ...[
                  const SizedBox(height: 30),
                  InkWell(
                    borderRadius: AppColors.borderRadiusAll,
                    onTap: () {
                      storeProvider.deleteItem(widget.editItemModel!.id);
                      Get.back();
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
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

      addStoreItemProvider.updateItem(widget.editItemModel!);

      NavigatorService().back();
    } else {
      NavigatorService().back();
    }
  }
}
