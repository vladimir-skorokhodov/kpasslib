import 'dart:typed_data';

import 'package:kpasslib/kpasslib.dart';
import 'package:pointycastle/export.dart';

/// Salt generator for protected data
// TODO: define constants for magic numbers
abstract class ProtectSaltGenerator {
  final StreamCipher _algo;
  ProtectSaltGenerator._(this._algo);

  /// Constructs [ProtectSaltGenerator] from based on provided
  /// [key] and [algorithm].
  factory ProtectSaltGenerator.fromKey({
    required List<int> key,
    required CrsAlgorithm algorithm,
  }) {
    return switch (algorithm) {
      CrsAlgorithm.salsa20 => _SalsaSaltGenerator(
          SHA256Digest().process(
            Uint8List.fromList(key),
          ),
        ),
      CrsAlgorithm.chaCha20 => _ChachaSaltGenerator(
          SHA512Digest().process(Uint8List.fromList(key)),
        ),
      _ => throw UnsupportedValueError('crsAlgorithm')
    };
  }

  /// Generates salt bytes requested [length].
  List<int> getSalt(int length) => _algo.process(Uint8List(length)).toList();
}

class _SalsaSaltGenerator extends ProtectSaltGenerator {
  static const _salsaNonce = [0xe8, 0x30, 0x09, 0x4b, 0x97, 0x20, 0x5d, 0x2a];

  _SalsaSaltGenerator(List<int> key) : super._(Salsa20Engine()) {
    _algo.init(
      false,
      ParametersWithIV(
        KeyParameter(
          Uint8List.fromList(key),
        ),
        Uint8List.fromList(_salsaNonce),
      ),
    );
  }
}

class _ChachaSaltGenerator extends ProtectSaltGenerator {
  _ChachaSaltGenerator(List<int> key) : super._(ChaCha7539Engine()) {
    _algo.init(
      false,
      ParametersWithIV(
        KeyParameter(
          Uint8List.fromList(key.sublist(0, 32)),
        ),
        Uint8List.fromList(
          key.sublist(32, 44),
        ),
      ),
    );
  }
}
