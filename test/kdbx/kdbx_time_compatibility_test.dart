import 'dart:convert';
import 'dart:typed_data';

import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('empty KDBX 4 timestamp is treated as absent', () {
    expect(KdbxTime.fromXmlText(text: '', isBinary: true).time, isNull);
  });

  test('nonempty binary timestamps must contain eight bytes', () {
    for (final size in [1, 2, 3, 4, 5, 6, 7, 9]) {
      expect(
        () => KdbxTime.fromXmlText(
          text: base64.encode(Uint8List(size)),
          isBinary: true,
        ),
        throwsFormatException,
      );
    }
  });

  test('valid binary timestamps round trip', () {
    final time = KdbxTime(DateTime.utc(2024, 1, 2));
    final encoded = time.toXmlText(isBinary: true)!;
    expect(KdbxTime.fromXmlText(text: encoded, isBinary: true).time, time.time);
  });

  test('KDBX 4 accepts ISO 8601 text timestamps', () {
    for (final text in ['2025-12-24T15:36:16Z', '2025-12-24T17:36:16+02:00']) {
      expect(
        KdbxTime.fromXmlText(text: text, isBinary: true).time,
        DateTime.utc(2025, 12, 24, 15, 36, 16),
      );
    }
    expect(
      () => KdbxTime.fromXmlText(text: 'invalid:timestamp', isBinary: true),
      throwsFormatException,
    );
  });

  test('empty entry time remains absent after serialization', () {
    final xml = XmlDocument.parse(
      '<Times><CreationTime></CreationTime>'
      '<LastModificationTime>AAAAAAAAAAA=</LastModificationTime></Times>',
    );
    final times = KdbxTimes.fromXml(node: xml.rootElement, isBinary: true);
    expect(times.creation.time, isNull);
    final saved = times.toXml(isBinary: true);
    final reread = KdbxTimes.fromXml(node: saved as XmlElement, isBinary: true);
    expect(reread.creation.time, isNull);
    expect(reread.modification.time, times.modification.time);
  });
}
