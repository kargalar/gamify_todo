import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Base card widget with slidable actions
/// Subclasses should implement the content and actions
abstract class BaseCard extends StatelessWidget {
  final String itemId;

  const BaseCard({
    super.key,
    required this.itemId,
  });

  /// Build the slidable actions
  List<SlidableAction> buildActions(BuildContext context);

  /// Build the main content of the card
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(itemId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.6,
        children: buildActions(context),
      ),
      child: buildContent(context),
    );
  }
}
