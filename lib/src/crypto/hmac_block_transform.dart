import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';

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

    while (reader.bytesLeft > 0) {
      final size = min(DataSize.mebi, reader.bytesLeft);
      final data = reader.readBytes(size);
      final hash = _getBlockHmac(key, index++, data);
      writer.writeBytes(hash);
      writer.writeUint32(size);
      writer.writeBytes(data);
    }

    writer.writeBytes(Uint8List(32));
    writer.writeUint32(0);
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
      final data = reader.readBytes(size);
      writer.writeBytes(data);

      if (!ListEquality().equals(hash, _getBlockHmac(key, index++, data))) {
        throw FileCorruptedError('invalid block hash');
      }
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
    return SHA512Digest().process(writer.bytes);
  }

  static List<int> _getBlockHmac(
    List<int> key,
    int index,
    List<int> data,
  ) {
    final hmac = HMac(SHA256Digest(), SHA256Digest().byteLength);
    final blockKey = getHmacKey(key: key, index: index);
    hmac.init(KeyParameter(Uint8List.fromList(blockKey)));

    final writer = BytesWriter();
    writer.writeUint64(index);
    writer.writeUint32(data.length);
    writer.writeBytes(data);

    return hmac.process(Uint8List.fromList(writer.bytes));
  }
}
