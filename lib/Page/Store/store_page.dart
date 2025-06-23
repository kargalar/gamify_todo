import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/Widget/store_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:provider/provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
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
          ],
        ),
        body: storeItems.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
    return Container(
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
            loginUser!.userCredit.toString(),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart,
            size: 80,
            color: AppColors.grey,
          ),
          SizedBox(height: 16),
          Text(
            "No items found", // TODO: Add to locale keys
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
