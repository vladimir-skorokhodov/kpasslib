import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../utils/merge_utils.dart';
import '../utils/xml_utils.dart';

/// A KDBX group.
class KdbxGroup extends KdbxItem {
  /// The collection of contained groups.
  var groups = <KdbxGroup>[];

  /// The collection of contained entries.
  var entries = <KdbxEntry>[];

  /// The group name.
  var name = '';

  /// The group notes.
  var notes = '';

  /// Whether group is expanded.
  bool? isExpanded;

  /// Whether searching is enabled in this group.
  bool? isSearchingEnabled;

  /// Tha last top visible entry of this group.
  KdbxUuid? lastTopVisibleEntry;

  KdbxGroup._(super.uuid) {
    icon = KdbxIcon.folder;
  }

  /// Constructs a [KdbxGroup] with [name], [icon] and [id].
  factory KdbxGroup.create({
    required String name,
    required KdbxIcon icon,
    required KdbxUuid id,
    KdbxGroup? parent,
    bool? enableAutoType,
    bool? enableSearching,
  }) {
    final group = KdbxGroup._(id);
    group.name = name;
    group.icon = icon;
    group.parent = parent;
    group.autoType.enabled = enableAutoType;
    group.isSearchingEnabled = enableSearching;
    group.isExpanded = true;
    group.times = KdbxTimes.fromTime();
    return group;
  }

  /// Clones [other] with [id].
  factory KdbxGroup.copyFrom(
    KdbxGroup other,
    KdbxUuid id,
  ) =>
      KdbxGroup._(id).._copyFrom(other);

  /// Constructs a [KdbxGroup] from the XML [node].
  factory KdbxGroup.fromXml(
    XmlNode node,
    KdbxHeader header,
    bool binaryTime, {
    KdbxGroup? parent,
  }) {
    final group = KdbxGroup._(KdbxUuid.zero);

    for (var element in node.childElements) {
      if (element.qualifiedName.isNotEmpty) {
        group._readNode(element, header, binaryTime);
      }
    }

    group.parent = parent;
    return group;
  }

  @override
  XmlNode toXml({
    required KdbxHeader header,
    required bool exportXml,
    required bool binaryTime,
    required bool includeHistory,
  }) {
    final node = XmlUtils.createElement(name: XmlElem.group, children: [
      (XmlElem.name, name),
      (XmlElem.notes, notes),
      (XmlElem.isExpanded, isExpanded),
      (XmlElem.groupDefaultAutoTypeSeq, autoType.defaultSequence),
      (XmlElem.enableAutoType, autoType.enabled),
      (XmlElem.enableSearching, isSearchingEnabled),
      (XmlElem.lastTopVisibleEntry, lastTopVisibleEntry),
    ]);

    final is41 = header.versionIsAtLeast(4, 1);
    super.appendToXml(
      node: node,
      is41: is41,
      binaryTime: binaryTime,
    );

    node.children.addAll(children.map((e) => e.toXml(
          header: header,
          exportXml: exportXml,
          binaryTime: binaryTime,
          includeHistory: true,
        )));

    return node;
  }

  @override
  merge(MergeObjectMap objectMap) {
    final remoteGroup = objectMap.remoteItems[uuid];
    if (remoteGroup is! KdbxGroup) {
      return;
    }

    if (times.modification.isBefore(remoteGroup.times.modification)) {
      _copyFrom(remoteGroup);
    }

    MergeUtils.mergeCollection(
      parent: this,
      remoteParent: remoteGroup,
      objectMap: objectMap,
    );

    for (final item in children) {
      item.merge(objectMap);
    }
  }

  /// The default autotype sequence
  String? get defaultAutoTypeSeq => autoType.defaultSequence;
  set defaultAutoTypeSeq(String? sequence) =>
      autoType.defaultSequence = sequence;

  /// Whether autotype is enabled.
  bool? get isAutoTypeEnabled => autoType.enabled;
  set isAutoTypeEnabled(bool? enabled) => autoType.enabled = enabled;

  /// All the entries contained in this group and in children.
  List<KdbxEntry> get allEntries =>
      [...entries, ...groups.expand((g) => g.allEntries)];

  /// All the groups contained in this group and in children.
  List<KdbxGroup> get allGroups =>
      groups.expand((g) => [g, ...g.allGroups]).toList();

  /// All the items contained in this group and in children,
  /// including this group itself.
  List<KdbxItem> get allItems =>
      [this, ...entries, ...groups.expand((g) => g.allItems)];

  /// All the children items.
  List<KdbxItem> get children => [...entries, ...groups];

  _copyFrom(KdbxGroup group) {
    name = group.name;
    notes = group.notes;
    icon = group.icon;
    customIcon = group.customIcon;
    times = KdbxTimes.copyFrom(group.times);

    isExpanded = group.isExpanded;
    defaultAutoTypeSeq = group.defaultAutoTypeSeq;
    isAutoTypeEnabled = group.isAutoTypeEnabled;
    isSearchingEnabled = group.isSearchingEnabled;
    lastTopVisibleEntry = group.lastTopVisibleEntry;
  }

  _readNode(XmlElement node, KdbxHeader header, bool binaryTime) {
    switch (node.qualifiedName) {
      case XmlElem.uuid:
        uuid = KdbxUuid.fromString(node.innerText);
      case XmlElem.name:
        name = node.innerText;
      case XmlElem.notes:
        notes = node.innerText;
      case XmlElem.icon:
        icon = KdbxIcon.fromInt(int.tryParse(node.innerText) ?? 0);
      case XmlElem.customIconID:
        customIcon = KdbxUuid.fromString(node.innerText);
      case XmlElem.tags:
        tags = XmlUtils.getTags(node);
      case XmlElem.times:
        times = KdbxTimes.fromXml(node: node, isBinary: binaryTime);
      case XmlElem.isExpanded:
        isExpanded = XmlUtils.getBoolean(node);
      case XmlElem.groupDefaultAutoTypeSeq:
        defaultAutoTypeSeq = node.innerText;
      case XmlElem.enableAutoType:
        isAutoTypeEnabled = XmlUtils.getBoolean(node);
      case XmlElem.enableSearching:
        isSearchingEnabled = XmlUtils.getBoolean(node);
      case XmlElem.lastTopVisibleEntry:
        lastTopVisibleEntry = KdbxUuid.fromString(node.innerText);
      case XmlElem.group:
        groups.add(KdbxGroup.fromXml(node, header, binaryTime, parent: this));
      case XmlElem.entry:
        entries.add(KdbxEntry.fromXml(
          node: node,
          header: header,
          binaryTime: binaryTime,
          parent: this,
        ));
      case XmlElem.customData:
        customData = KdbxCustomData.fromXml(node);
      case XmlElem.previousParentGroup:
        previousParent = KdbxUuid.fromString(node.innerText);
    }
  }
}
