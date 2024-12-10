import 'package:kpasslib/kpasslib.dart';

///A map of objects to merge.
class MergeObjectMap {
  /// The local items.
  final items = <KdbxUuid, KdbxItem>{};

  /// The locally deleted items.
  final deleted = <KdbxUuid>{};

  /// The remote items.
  var remoteItems = <KdbxUuid, KdbxItem>{};
}

/// The merge methods.
abstract final class MergeUtils {
  /// Merge remote collection with [remoteParent] to the local one with [parent].
  /// Implements 2P-set CRDT with tombstones stored in objectMap.deleted.
  /// Assumes tombstones are already merged.
  static mergeCollection({
    required KdbxGroup parent,
    required KdbxGroup remoteParent,
    required MergeObjectMap objectMap,
  }) {
    final newItems = <KdbxItem>[];

    for (final item in parent.children.where(
      // item deleted
      (i) => !objectMap.deleted.contains(i.uuid),
    )) {
      final remoteItem = objectMap.remoteItems[item.uuid];
      if (remoteItem == null ||
          !remoteItem.times.locationChange.isAfter(item.times.locationChange)) {
        // item added locally or is not changed/moved to this group locally later than remote
        newItems.add(item);
      }
    }

    for (final remoteItem in remoteParent.children.where(
      // item deleted or already processed as a local one
      (i) => !objectMap.deleted.contains(i.uuid),
    )) {
      final item = objectMap.items[remoteItem.uuid];
      if (item == null) {
        // item created remotely
        newItems.add(
          (KdbxItem.copyFrom(remoteItem, remoteItem.uuid)..parent = parent),
        );
      } else if (remoteItem.times.locationChange
          .isAfter(item.times.locationChange)) {
        // item moved to this group remotely later than local
        newItems.add(item..parent = parent);
      }
    }

    parent.entries = newItems.whereType<KdbxEntry>().toList();
    parent.groups = newItems.whereType<KdbxGroup>().toList();
  }
}
