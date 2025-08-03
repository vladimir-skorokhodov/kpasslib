import 'package:xml/xml.dart';

import '../../kpasslib.dart';
import '../utils/merge_utils.dart';
import '../utils/xml_utils.dart';

/// KDBX item structure, base for [KdbxEntry] and [KdbxGroup].
abstract class KdbxItem {
  /// The ID of the item.
  KdbxUuid uuid;

  /// The [KdbxTimes] property.
  var times = KdbxTimes();

  /// The standard icon.
  KdbxIcon icon = KdbxIcon.key;

  /// The custom icon ID.
  KdbxUuid? customIcon;

  /// The list of the tags.
  List<String>? tags;

  /// The parent group.
  KdbxGroup? parent;

  /// The previous parent.
  KdbxUuid? previousParent;

  /// The custom data property.
  KdbxCustomData? customData;

  /// Constructs the [KdbxItem] with [uuid].
  KdbxItem(this.uuid);

  /// Clones the [KdbxItem] from [other] with [id].
  static KdbxItem copyFrom(KdbxItem other, KdbxUuid id) => switch (other) {
        KdbxGroup g => KdbxGroup.copyFrom(g, id),
        KdbxEntry e => KdbxEntry.copyFrom(e, id),
        _ => throw UnsupportedValueError('Not implemented item type'),
      };

  /// Appends the item to the XML [node].
  appendToXml({
    required XmlNode node,
    required bool is41,
    required bool binaryTime,
  }) {
    XmlUtils.addChildren(parent: node, children: [
      (XmlElem.uuid, uuid),
      (XmlElem.icon, icon),
      (XmlElem.customIconID, customIcon),
      if (is41 || this is KdbxEntry) (XmlElem.tags, tags),
      if (is41) (XmlElem.previousParentGroup, previousParent),
    ]);

    final customDataNode = customData?.toXml(
      includeModificationTime: is41,
    );
    final timesNode = times.toXml(isBinary: binaryTime);

    node.children.addAll([
      customDataNode,
      timesNode,
    ].nonNulls);
  }

  /// Serializes the item to an XML node.
  XmlNode toXml({
    required KdbxHeader header,
    required bool exportXml,
    required bool binaryTime,
    required bool includeHistory,
  });

  ///Merges remote [objectMap] to the item.
  merge(MergeObjectMap objectMap);
}
