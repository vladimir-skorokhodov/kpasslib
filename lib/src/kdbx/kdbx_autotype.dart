import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../kpasslib.dart';
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
