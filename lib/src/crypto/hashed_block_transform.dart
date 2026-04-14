import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:kpasslib/kpasslib.dart';

import '../utils/byte_utils.dart';

/// Hashed block transformation functions
abstract final class HashedBlockTransform {
  static const int _blockSize = DataSize.mebi;
  static const int _hashSize = 32;
  static const int _endBlockSize = 0;

  /// Returns encrypted [data].
  static Uint8List encrypt(List<int> data) {
    final reader = BytesReader(data);
    final writer = BytesWriter();
    var index = 0;

    while (reader.bytesLeft > 0) {
      final size = min(_blockSize, reader.bytesLeft);
      final data = reader.readBytes(size);
      writer.writeUint32(index++);
      writer.writeBytes(sha256.convert(data).bytes);
      writer.writeUint32(size);
      writer.writeBytes(data);
    }

    writer.writeUint32(index);
    writer.writeBytes(Uint8List(_hashSize));
    writer.writeUint32(_endBlockSize);
    return writer.bytes;
  }

  /// Returns decrypted [data].
  static Uint8List decrypt(List<int> data) {
    final reader = BytesReader(data);
    final builder = BytesBuilder();

    next() {
      reader.readUint32(); // block index
      return (
        reader.readBytes(_hashSize),
        reader.readUint32()
      ); // hash and size
    }

    for (var (hash, size) = next(); size > 0; (hash, size) = next()) {
      final data = reader.readBytes(size);
      builder.add(data);

      if (!ListEquality().equals(hash, sha256.convert(data).bytes)) {
        throw FileCorruptedError('invalid block hash');
      }
    }

    return builder.toBytes();
  }
}
