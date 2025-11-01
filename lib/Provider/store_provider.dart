import 'package:flutter/material.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/store_item_model.dart';

class StoreProvider with ChangeNotifier {
  // burayı singelton yaptım gayet de iyi oldu neden normalde de context den kullanıyoruz anlamadım. galiba "watch" için olabilir. sibelton kısmını global timer için yaptım.
  static final StoreProvider _instance = StoreProvider._internal();
  factory StoreProvider() {
    return _instance;
  }

  StoreProvider._internal();
// ?? - kredi ve itemler - ye düşebilecek ama bu disipindena eksilmesine sebep oalcak
  List<ItemModel> storeItemList = [];

  void addItem(ItemModel itemModel) async {
    final int storeItemId = await ServerManager().addItem(itemModel: itemModel);

    itemModel.id = storeItemId;

    storeItemList.add(itemModel);

    notifyListeners();
  }

  void deleteItem(int id) async {
    await ServerManager().deleteItem(id: id);

    storeItemList.removeWhere((element) => element.id == id);

    notifyListeners();
  }

  void editItem(ItemModel itemModel) async {
    await ServerManager().updateItem(itemModel: itemModel);

    final int index = storeItemList.indexWhere((element) => element.id == itemModel.id);

    storeItemList[index] = itemModel;

    if (itemModel.isTimerActive != null && itemModel.isTimerActive!) {
      GlobalTimer().startStopTimer(storeItemModel: itemModel);
    }

    notifyListeners();
  }

  void setStateItems() {
    notifyListeners();
  }

  Future<void> loadItems() async {
    try {
      storeItemList = await ServerManager().getItems();
      notifyListeners();
    } catch (e) {
      LogService.error('❌ StoreProvider: Error loading items: $e');
    }
  }

  Future<void> reorderItems(List<ItemModel> reorderedItems) async {
    try {
      // Her item'e order index'ini ata
      for (int i = 0; i < reorderedItems.length; i++) {
        reorderedItems[i].order = i;
        LogService.debug('🔢 Item ${reorderedItems[i].title}: order = $i');
      }

      storeItemList = reorderedItems;
      await ServerManager().updateItemsOrder(items: storeItemList);
      notifyListeners();
      LogService.debug('✅ StoreProvider: Items reordered successfully - ${storeItemList.length} items saved');
    } catch (e) {
      LogService.error('❌ StoreProvider: Error reordering items: $e');
      rethrow;
    }
  }
}
