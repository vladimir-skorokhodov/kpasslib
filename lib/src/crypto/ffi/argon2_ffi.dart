import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../argon2.dart';

/// Native Argon2 hash call signature.
typedef Argon2HashC = Int32 Function(
  Pointer<Uint8> password,
  Uint32 passwordLen,
  Pointer<Uint8> salt,
  Uint32 saltLen,
  Uint32 parallelism,
  Uint32 memorySizeKB,
  Uint32 iterations,
  Uint32 hashLen,
  Uint32 type,
  Uint32 version,
  Pointer<Uint8> output,
);

/// Dart signature for the native Argon2 hash call.
typedef Argon2HashDart = int Function(
  Pointer<Uint8> password,
  int passwordLen,
  Pointer<Uint8> salt,
  int saltLen,
  int parallelism,
  int memorySizeKB,
  int iterations,
  int hashLen,
  int type,
  int version,
  Pointer<Uint8> output,
);

/// FFI [Argon2] implementation.
class Argon2Ffi extends Argon2 {
  static const int _defaultHashLength = 32;

  final Argon2HashDart _hashFn;

  /// Argon2 variant to use.
  final Argon2Type type;

  /// Argon2 version to use.
  final Argon2Version version;

  /// Number of parallel lanes.
  final int parallelism;

  /// Memory size in kibibytes.
  final int memorySizeKB;

  /// Number of passes (iterations).
  final int iterations;

  /// Salt value used for key derivation.
  final Uint8List salt;

  /// Creates a FFI-backed Argon2 instance.
  Argon2Ffi({
    required Argon2HashDart hashFn,
    this.type = Argon2Type.argon2id,
    this.version = Argon2Version.v13,
    required this.parallelism,
    required this.memorySizeKB,
    required this.iterations,
    required List<int> salt,
  })  : _hashFn = hashFn,
        salt = Uint8List.fromList(salt);

  @override
  Uint8List convert(List<int> password) {
    final passwordLength = password.length;
    final passwordPtr = malloc<Uint8>(passwordLength);
    final saltPtr = malloc<Uint8>(salt.length);
    final outputPtr = malloc<Uint8>(_defaultHashLength);

    try {
      passwordPtr.asTypedList(passwordLength).setAll(0, password);
      saltPtr.asTypedList(salt.length).setAll(0, salt);

      final status = _hashFn(
        passwordPtr,
        passwordLength,
        saltPtr,
        salt.length,
        parallelism,
        memorySizeKB,
        iterations,
        _defaultHashLength,
        type.value,
        version.value,
        outputPtr,
      );

      if (status != 0) {
        throw StateError('argon2_ffi failed with status code $status');
      }

      return Uint8List.fromList(outputPtr.asTypedList(_defaultHashLength));
    } finally {
      malloc.free(passwordPtr);
      malloc.free(saltPtr);
      malloc.free(outputPtr);
    }
  }
}
