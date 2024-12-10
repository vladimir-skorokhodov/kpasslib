import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../utils/xml_utils.dart';

/// A KDBX custom item.
class KdbxCustomItem {
  /// The text value of the custom item.
  String value;

  /// Time of the custom item modification.
  KdbxTime modification;

  /// Constructs a new [KdbxCustomItem] from provided [value] and [modification] time.
  KdbxCustomItem({required this.value, KdbxTime? modification})
      : modification = modification ?? KdbxTime();

  @override
  bool operator ==(Object other) =>
      other is KdbxCustomItem &&
      value == other.value &&
      modification == other.modification;

  @override
  int get hashCode {
    return value.hashCode + modification.hashCode;
  }
}

/// A KDBX custom data structure containing collection of [KdbxCustomItem].
class KdbxCustomData {
  /// The map of the custom data id to [KdbxCustomItem].
  var map = <String, KdbxCustomItem>{};

  /// Constructs an empty custom data.
  KdbxCustomData();

  /// Constructs a custom data from an XML node.
  factory KdbxCustomData.fromXml(XmlNode node) {
    final data = KdbxCustomData();

    for (var itemNode in node.childElements) {
      if (itemNode.qualifiedName == XmlElem.stringDictExItem) {
        String? key;
        String? value;
        var modification = KdbxTime();

        for (var e in itemNode.childElements) {
          switch (e.qualifiedName) {
            case XmlElem.key:
              key = e.innerText;
            case XmlElem.value:
              value = e.innerText;
            case XmlElem.lastModTime:
              modification = KdbxTime.fromXmlText(
                text: e.innerText,
                isBinary: true,
              );
          }
        }

        if (key != null && value != null) {
          data.map[key] =
              KdbxCustomItem(value: value, modification: modification);
        }
      }
    }

    return data;
  }

  /// Serializes the custom data to an XML element.
  XmlElement? toXml({required bool includeModificationTime}) {
    if (map.isEmpty) {
      return null;
    }

    return XmlElement(
      XmlName(XmlElem.customData),
      [],
      map.entries.map(
        (e) => XmlUtils.createElement(
            name: XmlElem.stringDictExItem,
            children: [
              (XmlElem.key, e.key),
              (XmlElem.value, e.value.value),
              if (includeModificationTime)
                (XmlElem.lastModTime, e.value.modification)
            ],
            binaryTime: true),
      ),
    );
  }
}
