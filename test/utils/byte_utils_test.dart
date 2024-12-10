import 'dart:typed_data';

import 'package:kpasslib/src/utils/byte_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Byte utils unit tests', () {
    final arr = List.generate(100, (i) => i);
    final data = Uint8List.fromList(arr).buffer.asByteData();

    test('provides basic int getters', () {
      final reader = BytesReader(arr);
      expect(reader.readUint8(), data.getUint8(0));
      expect(reader.readUint8(), data.getUint8(1));
      expect(reader.readUint8(), data.getUint8(2));
      expect(reader.readUint8(), data.getUint8(3));
      expect(reader.readUint16(), data.getUint16(4, Endian.little));
      expect(reader.readUint16(), data.getUint16(6, Endian.little));
      expect(reader.readUint16(), data.getUint16(8, Endian.little));
      expect(reader.readUint16(), data.getUint16(10, Endian.little));
      expect(reader.readUint32(), data.getUint32(12, Endian.little));
      expect(reader.readUint32(), data.getUint32(16, Endian.little));
      expect(reader.readInt32(), data.getInt32(20, Endian.little));
      expect(reader.readInt32(), data.getInt32(24, Endian.little));
      expect(reader.readUint64(), data.getUint64(28, Endian.little));
      expect(reader.readUint64(), data.getUint64(36, Endian.little));
      expect(reader.readInt64(), data.getInt64(44, Endian.little));
      expect(reader.readInt64(), data.getInt64(52, Endian.little));
    });

    test('gets uint64', () {
      final reader = BytesReader(arr);
      expect(reader.readUint64(), 0x0706050403020100);
      expect(reader.readUint8(), 8);
    });

    test('provides basic int setters', () {
      final writer = BytesWriter();
      writer.writeUint8(data.getUint8(0));
      writer.writeUint8(data.getUint8(1));
      writer.writeUint8(data.getInt8(2));
      writer.writeUint8(data.getInt8(3));
      writer.writeUint16(data.getUint16(4, Endian.little));
      writer.writeUint16(data.getUint16(6, Endian.little));
      writer.writeUint16(data.getUint16(8, Endian.little));
      writer.writeUint16(data.getUint16(10, Endian.little));
      writer.writeUint32(data.getUint32(12, Endian.little));
      writer.writeUint32(data.getUint32(16, Endian.little));
      writer.writeInt32(data.getUint32(20, Endian.little));
      writer.writeInt32(data.getUint32(24, Endian.little));
      writer.writeUint64(data.getUint64(28, Endian.little));
      writer.writeUint64(data.getUint64(36, Endian.little));
      writer.writeInt64(data.getUint64(44, Endian.little));
      writer.writeInt64(data.getUint64(52, Endian.little));

      expect(writer.bytes, arr.sublist(0, 60));
    });

    test('sets uint64', () {
      final writer = BytesWriter();
      writer.writeUint64(0x0706050403020100);
      writer.writeUint8(8);
      expect(writer.bytes, arr.sublist(0, 9));
    });

    test('reads bytes after pos', () {
      var reader = BytesReader(arr);
      var bytes = reader.readBytesToEnd();
      expect(bytes, arr);

      bytes = reader.readBytesToEnd();
      expect(bytes.length, 0);

      reader = BytesReader(arr);
      reader.readUint8();
      reader.readUint64();
      bytes = reader.readBytesToEnd();
      expect(bytes, arr.sublist(9));

      bytes = reader.readBytesToEnd();
      expect(bytes.length, 0);

      reader = BytesReader(arr);
      for (var i = 0; i < 100; i++) {
        reader.readUint8();
      }

      bytes = reader.readBytesToEnd();
      expect(bytes.length, 0);
    });

    test('reads number of bytes after pos', () {
      var reader = BytesReader(arr);
      var bytes = reader.readBytes(100);
      expect(bytes, arr);

      bytes = reader.readBytesToEnd();
      expect(bytes.length, 0);

      reader = BytesReader(arr);
      reader.readUint8();
      reader.readUint64();
      bytes = reader.readBytes(50);
      expect(bytes, arr.sublist(9, 59));

      bytes = reader.readBytesToEnd();
      expect(bytes.length, 41);

      reader = BytesReader(arr);
      for (var i = 0; i < 100; i++) {
        reader.readUint8();
      }
      bytes = reader.readBytes(5);
      expect(bytes.length, 0);
    });
  });
}
