import 'package:flutter/material.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Model/trait_model.dart';

class TraitProvider with ChangeNotifier {
  // singelton
  TraitProvider._privateConstructor();
  static final TraitProvider _instance = TraitProvider._privateConstructor();
  factory TraitProvider() {
    return _instance;
  }

  List<TraitModel> traitList = [];

  void editTrait(TraitModel traitModel) async {
    traitList[traitList.indexWhere((element) => element.id == traitModel.id)] = traitModel;

    await ServerManager().updateTrait(traitModel: traitModel);

    notifyListeners();
  }

  void addTrait(TraitModel traitModel) async {
    final int traitId = await ServerManager().addTrait(traitModel: traitModel);

    traitModel.id = traitId;

    traitList.add(traitModel);

    notifyListeners();
  }

  void removeTrait(int id) async {
    await ServerManager().deleteTrait(id: id);

    traitList.removeWhere((element) => element.id == id);

    notifyListeners();
  }
}
