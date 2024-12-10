import 'dart:convert';

import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../utils/byte_utils.dart';
import '../utils/xml_utils.dart';

/// Wraps DateTime type to support null value comparison.
class KdbxTime {
  /// The start of the epoch time point.
  static final zero = DateTime.fromMicrosecondsSinceEpoch(0);

  /// The underlying nullable time value.
  final DateTime? time;

  static const _epochSeconds = 62135596800;

  /// Constructs a [KdbxTime] from provided [time].
  KdbxTime([this.time]);

  /// The [time] value or [zero] in case first is null.
  DateTime get timeOrZero => time ?? zero;

  /// Returns true if this occurs after [other].
  bool isAfter(KdbxTime other) => timeOrZero.isAfter(other.timeOrZero);

  /// Returns true if this occurs before [other].
  bool isBefore(KdbxTime other) => timeOrZero.isBefore(other.timeOrZero);

  /// Returns true if this occurs at the same moment as [other].
  bool isAtSameMomentAs(KdbxTime other) =>
      timeOrZero.isAtSameMomentAs(other.timeOrZero);

  /// Compares this  to [other], returning zero if the values are equal.
  int compareTo(KdbxTime other) => timeOrZero.compareTo(other.timeOrZero);

  @override
  operator ==(Object other) => other is KdbxTime && isAtSameMomentAs(other);

  @override
  int get hashCode => timeOrZero.hashCode;

  /// Constructs a [KdbxTime] from the current moment of time.
  factory KdbxTime.now() => KdbxTime(DateTime.now());

  /// Constructs a [KdbxTime] from the XML node [text].
  factory KdbxTime.fromXmlText({
    required String text,
    required bool isBinary,
  }) =>
      KdbxTime(_fromString(
        string: text,
        isBinary: isBinary,
      ));

  /// Serializes this into an XML string.
  String? toXmlText({required bool isBinary}) {
    final value = time;

    if (value == null) {
      return null;
    }

    if (!isBinary) {
      return value.toIso8601String();
    }

    final secondsSinceEpoch =
        value.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerSecond;
    final seconds = secondsSinceEpoch.round() + _epochSeconds;
    return base64.encode((BytesWriter()..writeInt64(seconds)).bytes);
  }

  static DateTime? _fromString(
      {required String string, required bool isBinary}) {
    if (!isBinary) {
      return DateTime.tryParse(string);
    }

    try {
      final seconds = BytesReader(base64.decode(string)).readInt64();
      final secondsSinceEpoch = seconds - _epochSeconds;
      return DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000,
          isUtc: true);
    } on Exception {
      return null;
    }
  }
}

/// Represents KDBX times type
class KdbxTimes {
  /// The creation time.
  var creation = KdbxTime();

  /// The last modification time.
  var modification = KdbxTime();

  /// The last access time.
  var access = KdbxTime();

  /// The expiry time.
  var expiry = KdbxTime();

  /// The last location change time.
  var locationChange = KdbxTime();

  /// Whether item can be expired.
  var expires = false;

  /// The count of usages.
  var usageCount = 0;

  /// Constructs a default [KdbxTimes] object.
  KdbxTimes();

  /// Constructs a [KdbxTimes] from the [dateTime] value.
  factory KdbxTimes.fromTime([DateTime? dateTime]) {
    dateTime ??= DateTime.now();
    final times = KdbxTimes();
    times.creation = KdbxTime(dateTime);
    times.modification = KdbxTime(dateTime);
    times.access = KdbxTime(dateTime);
    return times;
  }

  /// Clones the [other].
  factory KdbxTimes.copyFrom(KdbxTimes other) {
    final times = KdbxTimes();
    times.creation = other.creation;
    times.modification = other.modification;
    times.access = other.access;
    times.expiry = other.expiry;
    times.expires = other.expires;
    times.usageCount = other.usageCount;
    times.locationChange = other.locationChange;
    return times;
  }

  /// Constructs a [KdbxTimes] from the XML [node].
  factory KdbxTimes.fromXml({
    required XmlElement node,
    required bool isBinary,
  }) {
    final times = KdbxTimes();

    for (var element in node.childElements) {
      if (element.qualifiedName.isNotEmpty) {
        times._readNode(element, isBinary);
      }
    }

    return times;
  }

  /// Serializes this to an XML node.
  XmlNode toXml({required bool isBinary}) => XmlUtils.createElement(
        name: XmlElem.times,
        children: [
          (XmlElem.creationTime, creation),
          (XmlElem.lastModTime, modification),
          (XmlElem.lastAccessTime, access),
          (XmlElem.expiryTime, expiry),
          (XmlElem.expires, expires),
          (XmlElem.usageCount, usageCount),
          (XmlElem.locationChanged, locationChange),
        ],
        binaryTime: isBinary,
      );

  /// Updates the [modification] and [access] to the current moment of time.
  touch() {
    final now = KdbxTime.now();
    modification = now;
    access = now;
  }

  _readNode(XmlElement node, bool isBinary) {
    switch (node.qualifiedName) {
      case XmlElem.creationTime:
        creation =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: isBinary);
      case XmlElem.lastModTime:
        modification =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: isBinary);
      case XmlElem.lastAccessTime:
        access = KdbxTime.fromXmlText(text: node.innerText, isBinary: isBinary);
      case XmlElem.locationChanged:
        locationChange =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: isBinary);
      case XmlElem.expiryTime:
        expiry = KdbxTime.fromXmlText(text: node.innerText, isBinary: isBinary);
      case XmlElem.expires:
        expires = XmlUtils.getBoolean(node) ?? false;
      case XmlElem.usageCount:
        usageCount = int.tryParse(node.innerText) ?? 0;
    }
  }
}
