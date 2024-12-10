import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';

import '../utils/byte_utils.dart';

/// Hashed block transformation functions
// TODO: define constants for magic numbers
abstract final class HashedBlockTransform {
  /// Returns encrypted [data].
  static List<int> encrypt(List<int> data) {
    final reader = BytesReader(data);
    final writer = BytesWriter();
    var index = 0;

    while (reader.bytesLeft > 0) {
      final size = min(DataSize.mebi, reader.bytesLeft);
      final data = Uint8List.fromList(reader.readBytes(size));
      writer.writeUint32(index++);
      writer.writeBytes(SHA256Digest().process(data));
      writer.writeUint32(size);
      writer.writeBytes(data);
    }

    writer.writeUint32(index);
    writer.writeBytes(Uint8List(32));
    writer.writeUint32(0);
    return writer.bytes;
  }

  /// Returns decrypted [data].
  static List<int> decrypt(List<int> data) {
    final reader = BytesReader(data);
    final builder = BytesBuilder();

    next() {
      reader.readUint32(); // block index
      return (reader.readBytes(32), reader.readUint32()); //hash and size
    }

    for (var (hash, size) = next(); size > 0; (hash, size) = next()) {
      final data = Uint8List.fromList(reader.readBytes(size));
      builder.add(data);

      if (!ListEquality().equals(hash, SHA256Digest().process(data))) {
        throw FileCorruptedError('invalid block hash');
      }
    }

    return builder.toBytes();
  }
}
