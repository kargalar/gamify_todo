import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/accessible.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:gamify_todo/Page/Store/Widget/store_item.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Provider/navbar_provider.dart';
import 'package:gamify_todo/Provider/store_provider.dart';
import 'package:provider/provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: storeItems.isEmpty
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
