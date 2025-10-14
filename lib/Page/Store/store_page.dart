import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/Widget/store_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:provider/provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeItems = context.watch<StoreProvider>().storeItemList;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        NavbarProvider().updateIndex(1);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.Store.tr()),
          leading: const SizedBox(),
          actions: [
            _buildCreditDisplay(),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reset_credit') {
                  _showResetCreditDialog();
                } else if (value == 'reset_store_progress') {
                  _showResetStoreProgressDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'reset_credit',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(LocaleKeys.ResetCredit.tr()),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reset_store_progress',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(LocaleKeys.ResetStoreProgress.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: storeItems.isEmpty
            ? _buildEmptyState()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: storeItems.length,
                itemBuilder: (context, index) {
                  return StoreItem(
                    storeItemModel: storeItems[index],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCreditDisplay() {
    final userProvider = context.watch<UserProvider>();

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.help_outline, color: AppColors.main),
                const SizedBox(width: 8),
                Text(LocaleKeys.HowToEarnCredits.tr()),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.EarnCreditsDescription.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEarnCreditItem(
                  Icons.check_box_rounded,
                  LocaleKeys.CheckboxTasks.tr(),
                  LocaleKeys.CheckboxTasksDesc.tr(),
                ),
                const SizedBox(height: 12),
                _buildEarnCreditItem(
                  Icons.add_circle_outline,
                  LocaleKeys.CounterTasks.tr(),
                  LocaleKeys.CounterTasksDesc.tr(),
                ),
                const SizedBox(height: 12),
                _buildEarnCreditItem(
                  Icons.timer_outlined,
                  LocaleKeys.TimerTasks.tr(),
                  LocaleKeys.TimerTasksDesc.tr(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.main.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.main, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                            children: [
                              TextSpan(
                                text: '${LocaleKeys.CreditRate.tr()}\n',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.main,
                                ),
                              ),
                              TextSpan(
                                text: LocaleKeys.CreditExample.tr(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.Understood.tr()),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.panelBackground2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(
              userProvider.userCredit.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.monetization_on,
              size: 20,
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnCreditItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.main),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart,
            size: 80,
            color: AppColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.NoItemsFound.tr(),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetCreditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetCredit.tr()),
          content: Text(LocaleKeys.ResetCreditWarning.tr()),
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
                await _resetCredit();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showResetStoreProgressDialog() {
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
                await _resetStoreProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetCredit() async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.resetCredit();
      setState(() {});
      Helper().getMessage(message: LocaleKeys.ResetCreditSuccess.tr());
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }

  Future<void> _resetStoreProgress() async {
    try {
      final storeProvider = context.read<StoreProvider>();

      // Reset all store items' progress to their initial values
      for (final item in storeProvider.storeItemList) {
        // Reset counter items
        if (item.type == TaskTypeEnum.COUNTER) {
          item.currentCount = 0;
        }
        // Reset timer items
        else if (item.type == TaskTypeEnum.TIMER) {
          item.currentDuration = Duration.zero;
          // Also stop timer if it's active
          if (item.isTimerActive == true) {
            item.isTimerActive = false;
          }
        }

        await HiveService().updateItem(item);
      }

      // Update the provider to reflect changes in UI
      storeProvider.setStateItems();
      setState(() {});

      Helper().getMessage(message: LocaleKeys.ResetStoreProgressSuccess.tr());
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }
}
