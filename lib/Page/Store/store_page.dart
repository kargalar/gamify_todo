import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gamify_todo/General/accessible.dart';
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

class _StorePageState extends State<StorePage> {
  @override
  Widget build(BuildContext context) {
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
            Text(loginUser!.userCredit.toString(), style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 2),
            const Icon(Icons.monetization_on),
            const SizedBox(width: 10),
          ],
        ),
        body: ListView.builder(
          itemCount: context.watch<StoreProvider>().storeItemList.length,
          itemBuilder: (context, index) {
            return StoreItem(
              storeItemModel: context.read<StoreProvider>().storeItemList[index],
            );
          },
        ),
      ),
    );
  }
}
