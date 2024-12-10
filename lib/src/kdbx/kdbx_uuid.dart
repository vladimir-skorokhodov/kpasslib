import 'dart:convert';

import '../crypto/crypto_utils.dart';
import 'kdbx_error.dart';

/// A KDBX identifier.
class KdbxUuid {
  static const _uuidLength = 16;
  static const _uuidStringLength = 24;
  final String _uuid;

  const KdbxUuid._(this._uuid);

  /// The 0-filled UUID value.
  static const KdbxUuid zero = KdbxUuid._('AAAAAAAAAAAAAAAAAAAAAA==');

  /// Constructs a [KdbxUuid] from the string [string] presentation.
  factory KdbxUuid.fromString(
    String string, {
    Set<KdbxUuid> prohibited = const {},
  }) {
    if (string.isEmpty) {
      return KdbxUuid.random(prohibited: prohibited);
    }

    if (prohibited.any((id) => id._uuid == string)) {
      throw InvalidStateError('UUID duplicate'); // TODO: test the exception
    }

    if (string.length != _uuidStringLength) {
      throw UnsupportedValueError('bad UUID length: ${string.length}');
    }

    return KdbxUuid._(string);
  }

  /// Constructs a [KdbxUuid] from the [bytes] list.
  factory KdbxUuid.fromBytes(
    List<int> bytes, {
    Set<KdbxUuid> prohibited = const {},
  }) =>
      KdbxUuid.fromString(bytes.isEmpty ? '' : base64.encode(bytes),
          prohibited: prohibited);

  /// Constructs a random [KdbxUuid].
  factory KdbxUuid.random({Set<KdbxUuid> prohibited = const {}}) {
    try {
      return KdbxUuid.fromBytes(
        CryptoUtils.randomBytes(_uuidLength),
        prohibited: prohibited,
      );
    } on InvalidStateError catch (_) {
      return KdbxUuid.random(prohibited: prohibited);
    }
  }

  /// The id as string.
  String get string => _uuid;

  /// The id as bytes list.
  List<int> get bytes => base64.decode(_uuid);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KdbxUuid && _uuid == other._uuid;

  @override
  int get hashCode => _uuid.hashCode;
}
