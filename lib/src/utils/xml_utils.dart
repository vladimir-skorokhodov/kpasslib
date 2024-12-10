import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

/// An utility functions to work with XML.
abstract final class XmlUtils {
  static const _tagsSplitRegex = r'\s*[;,:]\s*';

  /// Searches for a child node with [name] from [parent].
  /// Returns null in case it was not found.
  // TODO: add missing tests
  static XmlNode? getChildNodeOrNull(XmlNode parent, String name) =>
      parent.childElements
          .firstWhereOrNull((element) => element.qualifiedName == name);

  /// Searches for a child node with [name] from [parent].
  /// Throws [FileCorruptedError] with [errorMsgIfAbsent] in case it was not found.
  static XmlNode getChildNode(
    XmlNode parent,
    String name,
    String errorMsgIfAbsent,
  ) {
    final found = getChildNodeOrNull(parent, name);

    if (found == null) {
      throw FileCorruptedError(errorMsgIfAbsent);
    }

    return found;
  }

  /// Returns a list of pair with children name and text.
  static List<(String, String)> getChildrenView(XmlNode parent) => List.from(
        parent.childElements.map(
          (e) => (e.qualifiedName, e.innerText),
        ),
      );

  /// Reads boolean value from the XML [node].
  static bool? getBoolean(XmlElement? node) =>
      switch (node?.innerText.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null
      };

  /// Reads boolean attribute from the XML [node].
  static bool getBooleanAttribute(XmlElement node, String attribute) =>
      node.getAttribute(attribute)?.toLowerCase() == 'true';

  /// Returns list of tags from the XML [node] text.
  static List<String> getTags(XmlElement node) => node.innerText
      .split(RegExp(_tagsSplitRegex))
      .map((t) => t.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Creates an empty XML document with rootNode
  static XmlDocument create(String rootNode,
          {String extraAttributes = 'standalone="yes"'}) =>
      XmlDocument.parse(
          '<?xml version="1.0" encoding="utf-8" $extraAttributes?><$rootNode/>');

  /// Appends the [children] to the [parent] XML node.
  static addChildren({
    required XmlNode parent,
    required List<(String, Object?)> children,
    bool binaryTime = false,
  }) {
    parent.children.addAll(children
        .map((e) => (e.$1, _toSting(value: e.$2, binaryTime: binaryTime)))
        .where((e) => e.$2 != null)
        .map((e) {
      final text = e.$2;
      return text == null
          ? null
          : (XmlElement(XmlName(e.$1))..innerText = text);
    }).nonNulls);
  }

  /// Creates an XML element with [name] and [children].
  static XmlElement createElement({
    required String name,
    List<(String, Object?)>? children,
    bool binaryTime = false,
  }) {
    final node = XmlElement(XmlName(name));

    if (children != null) {
      addChildren(
        parent: node,
        children: children,
        binaryTime: binaryTime,
      );
    }

    return node;
  }

  static String? _toSting({Object? value, bool binaryTime = false}) {
    if (value is String) {
      return value;
    } else if (value is int) {
      return value.toString();
    } else if (value is KdbxTime) {
      return value.toXmlText(isBinary: binaryTime);
    } else if (value is bool) {
      return value ? 'True' : 'False';
    } else if (value is List<int>) {
      return base64.encode(value);
    } else if (value is KdbxUuid) {
      return value.string;
    } else if (value is Icon) {
      return value.value.toString();
    } else if (value is List<String>) {
      return value.fold(
          '',
          (previousValue, element) => previousValue?.isNotEmpty ?? false
              ? '$previousValue;$element'
              : element);
    }
    return null;
  }
}
