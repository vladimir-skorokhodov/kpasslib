import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kpasslib/kpasslib.dart';

import 'stream_cipher.dart';

/// Salt generator for protected data
class ProtectSaltGenerator {
  static final Uint8List _salsaNonce = Uint8List.fromList(
    [0xe8, 0x30, 0x09, 0x4b, 0x97, 0x20, 0x5d, 0x2a],
  );

  final StreamCipher _cipher;
  final Uint8List _nonce;
  var _position = 0;

  ProtectSaltGenerator._(this._cipher, this._nonce);

  /// Constructs [ProtectSaltGenerator] from based on provided
  /// [key] and [algorithm].
  factory ProtectSaltGenerator({
    required List<int> key,
    required CrsAlgorithm algorithm,
  }) {
    switch (algorithm) {
      case CrsAlgorithm.salsa20:
        final salsaKey = Uint8List.fromList(sha256.convert(key).bytes);
        return ProtectSaltGenerator._(
          Crypto.engine.createSalsa20(key: salsaKey),
          _salsaNonce,
        );
      case CrsAlgorithm.chaCha20:
        final hash512 = Uint8List.fromList(sha512.convert(key).bytes);
        return ProtectSaltGenerator._(
          Crypto.engine.createChaCha20(key: hash512.sublist(0, 32)),
          hash512.sublist(32, 44),
        );
      default:
        throw UnsupportedValueError('crsAlgorithm');
    }
  }

  /// Generates salt bytes requested [length].
  Uint8List getSalt(int length) {
    if (length == 0) return Uint8List(0);

    final offset = _position % 64;
    final counter = _position ~/ 64;
    final bytesNeeded = length + offset;
    final blocks = (bytesNeeded + 63) ~/ 64;

    final keystream = _cipher.transform(
      data: Uint8List(blocks * 64),
      nonce: _nonce,
      counter: counter,
    );

    final result = keystream.sublist(offset, offset + length);
    _position += length;
    return result;
  }
}
