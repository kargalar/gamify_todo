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

  /// Build the slidable actions for the end (right side when sliding left)
  List<SlidableAction> buildActions(BuildContext context);

  /// Build the slidable actions for the start (left side when sliding right)
  /// Override this method to add start actions
  List<SlidableAction>? buildStartActions(BuildContext context) => null;

  /// Build the main content of the card
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final startActions = buildStartActions(context);

    return Slidable(
      key: ValueKey(itemId),
      startActionPane: startActions != null && startActions.isNotEmpty
          ? ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.3,
              children: startActions,
            )
          : null,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.6,
        children: buildActions(context),
      ),
      child: buildContent(context),
    );
  }
}
