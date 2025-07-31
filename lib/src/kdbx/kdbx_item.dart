import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../kpasslib.dart';
import '../utils/merge_utils.dart';
import '../utils/xml_utils.dart';

/// Autotype options for obfuscation.
enum AutoTypeObfuscationOptions {
  /// No obfuscation.
  none(0),

  /// Obfuscation via clipboard.
  useClipboard(1);

  const AutoTypeObfuscationOptions(this._value);
  final int _value;

  factory AutoTypeObfuscationOptions.fromInt(int? value) =>
      values.elementAtOrNull(value ?? 0) ?? none;
}

/// An autotype item.
class KdbxAutoTypeItem {
  /// The window name.
  var window = '';

  /// The keystroke sequence of autotype.
  var keystrokeSequence = '';

  /// Constructs a [KdbxAutoTypeItem].
  KdbxAutoTypeItem({
    required this.window,
    required this.keystrokeSequence,
  });

  @override
  bool operator ==(Object other) =>
      other is KdbxAutoTypeItem &&
      window == other.window &&
      keystrokeSequence == other.keystrokeSequence;

  @override
  int get hashCode {
    return window.hashCode + keystrokeSequence.hashCode;
  }
}

/// An autotype structure.
class KdbxAutoType {
  /// Whether autotype is enabled.
  bool? enabled;

  /// The obfuscation value.
  AutoTypeObfuscationOptions obfuscation;

  /// The default autotype sequence.
  String? defaultSequence;

  /// The collection of autotype items.
  List<KdbxAutoTypeItem> items;

  /// Constructs an empty [KdbxAutoType] object.
  KdbxAutoType({
    this.enabled,
    this.obfuscation = AutoTypeObfuscationOptions.none,
    this.defaultSequence,
    List<KdbxAutoTypeItem>? items,
  }) : items = items ?? [];

  /// Clones the [other] autotype.
  factory KdbxAutoType.copyFrom(KdbxAutoType other) => KdbxAutoType(
      enabled: other.enabled,
      obfuscation: other.obfuscation,
      defaultSequence: other.defaultSequence,
      items: List.from(other.items));

  /// Constructs the [KdbxAutoType] from the XML [element].
  factory KdbxAutoType.fromXml(XmlElement element) {
    final autoType = KdbxAutoType();

    for (final e in element.childElements) {
      switch (e.qualifiedName) {
        case XmlElem.autoTypeEnabled:
          autoType.enabled = XmlUtils.getBoolean(e) ?? true;
        case XmlElem.autoTypeObfuscation:
          autoType.obfuscation =
              AutoTypeObfuscationOptions.fromInt(int.tryParse(e.innerText));
        case XmlElem.autoTypeDefaultSequence:
          autoType.defaultSequence = e.innerText;
        case XmlElem.autoTypeItem:
          {
            final map = Map.fromEntries(e.childElements
                .map((e) => MapEntry(e.qualifiedName, e.innerText)));

            final window = map[XmlElem.window];
            final keystrokeSequence = map[XmlElem.keystrokeSequence];

            if (window != null && keystrokeSequence != null) {
              autoType.items.add(KdbxAutoTypeItem(
                  window: window, keystrokeSequence: keystrokeSequence));
            }
          }
      }
    }

    return autoType;
  }

  ///Serializes the autotype to an XML element.
  XmlElement toXml() =>
      XmlUtils.createElement(name: XmlElem.autoType, children: [
        (XmlElem.autoTypeEnabled, enabled),
        (XmlElem.autoTypeObfuscation, obfuscation._value),
        (XmlElem.autoTypeDefaultSequence, defaultSequence)
      ])
        ..children.addAll(items.map((item) {
          return XmlUtils.createElement(name: XmlElem.autoTypeItem, children: [
            (XmlElem.window, item.window),
            (XmlElem.keystrokeSequence, item.keystrokeSequence)
          ]);
        }));

  @override
  bool operator ==(Object other) =>
      other is KdbxAutoType &&
      enabled == other.enabled &&
      obfuscation == other.obfuscation &&
      defaultSequence == other.defaultSequence &&
      ListEquality().equals(items, other.items);

  @override
  int get hashCode =>
      enabled.hashCode +
      obfuscation.hashCode +
      defaultSequence.hashCode +
      items.hashCode;
}

/// KDBX item structure, base for [KdbxEntry] and [KdbxGroup].
abstract class KdbxItem {
  /// The ID of the item.
  KdbxUuid uuid;

  /// The autotype.
  var autoType = KdbxAutoType();

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
