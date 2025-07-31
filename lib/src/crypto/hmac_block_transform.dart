import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:kpasslib/kpasslib.dart';

import '../utils/byte_utils.dart';

/// HMAC block transformation functions
// TODO: define constants for magic numbers
abstract final class HmacBlockTransform {
  /// Returns encrypted [data].
  static List<int> encrypt({
    required List<int> data,
    required List<int> key,
  }) {
    final reader = BytesReader(data);
    final writer = BytesWriter();
    var index = 0;

    writeBlock(List<int> blockData) {
      final hash = _getBlockHmac(key, index++, blockData);
      writer.writeBytes(hash);
      writer.writeUint32(blockData.length);
      writer.writeBytes(blockData);
    }

    while (reader.bytesLeft > 0) {
      final size = min(DataSize.mebi, reader.bytesLeft);
      final blockData = reader.readBytes(size);
      writeBlock(blockData);
    }

    writeBlock([]);

    return writer.bytes;
  }

  /// Returns decrypted [data].
  static List<int> decrypt({
    required List<int> data,
    required List<int> key,
  }) {
    final reader = BytesReader(data);
    final writer = BytesWriter();
    var index = 0;

    next() => (reader.readBytes(32), reader.readUint32());

    for (var (hash, size) = next(); size > 0; (hash, size) = next()) {
      final blockData = reader.readBytes(size);

      if (!ListEquality()
          .equals(hash, _getBlockHmac(key, index++, blockData))) {
        throw FileCorruptedError('invalid block hash');
      }

      writer.writeBytes(blockData);
    }

    return writer.bytes;
  }

  /// Returns hash of the [key].
  static List<int> getHmacKey({
    required List<int> key,
    required int index,
  }) {
    final writer = BytesWriter();
    writer.writeUint64(index);
    writer.writeBytes(key);
    return sha512.convert(writer.bytes).bytes;
  }

  static List<int> _getBlockHmac(
    List<int> key,
    int index,
    List<int> data,
  ) {
    final writer = BytesWriter();
    writer.writeUint64(index);
    writer.writeUint32(data.length);
    writer.writeBytes(data);

    final blockKey = getHmacKey(key: key, index: index);
    return Hmac(sha256, blockKey).convert(writer.bytes).bytes;
  }
}
