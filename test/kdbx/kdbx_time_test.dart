import 'dart:convert';
import 'dart:typed_data';

import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('KdbxTime unit tests', () {
    test('treats empty and whitespace-only KDBX 4 timestamps as absent', () {
      for (final text in ['', '   ', '\n\t ']) {
        expect(KdbxTime.fromXmlText(text: text, isBinary: true).time, isNull);
      }
    });

    test('returns null for nonempty binary timestamps not equal to eight bytes',
        () {
      for (final size in [1, 2, 3, 4, 5, 6, 7, 9]) {
        expect(
          KdbxTime.fromXmlText(
            text: base64.encode(Uint8List(size)),
            isBinary: true,
          ).time,
          isNull,
        );
      }
    });

    test('round trips valid binary timestamps', () {
      final time = KdbxTime(DateTime.utc(2024, 1, 2));
      final encoded = time.toXmlText(isBinary: true)!;
      expect(
          KdbxTime.fromXmlText(text: encoded, isBinary: true).time, time.time);
    });

    test('accepts ISO 8601 text timestamps in binary mode', () {
      for (final text in [
        '2025-12-24T15:36:16Z',
        '2025-12-24T17:36:16+02:00',
        '  2025-12-24T15:36:16Z\n',
      ]) {
        expect(
          KdbxTime.fromXmlText(text: text, isBinary: true).time,
          DateTime.utc(2025, 12, 24, 15, 36, 16),
        );
      }
      expect(
        KdbxTime.fromXmlText(text: '2025-12-24', isBinary: true).time,
        DateTime(2025, 12, 24),
      );
    });

    test('returns null on invalid timestamp in binary mode', () {
      for (final text in ['invalid:timestamp', 'not-a-timestamp']) {
        expect(
          KdbxTime.fromXmlText(text: text, isBinary: true).time,
          isNull,
        );
      }
    });
  });

  group('KdbxTimes unit tests', () {
    test('keeps empty entry time absent after serialization', () {
      final xml = XmlDocument.parse(
        '<Times><CreationTime></CreationTime>'
        '<LastModificationTime>AAAAAAAAAAA=</LastModificationTime></Times>',
      );
      final times = KdbxTimes.fromXml(node: xml.rootElement, isBinary: true);
      expect(times.creation.time, isNull);

      final saved = times.toXml(isBinary: true) as XmlElement;
      expect(saved.findElements('CreationTime'), isEmpty);

      final reread = KdbxTimes.fromXml(node: saved, isBinary: true);
      expect(reread.creation.time, isNull);
      expect(reread.modification.time, times.modification.time);
    });
  });
}
