import 'dart:typed_data';

/// Argon2 algorithm variants supported by KeePass.
///
/// `argon2d` is optimized for resistance against GPU cracking and
/// uses data-dependent memory access. `argon2id` combines both
/// data-dependent and data-independent memory access for better
/// protection against side-channel attacks.
enum Argon2Type {
  /// Argon2d variant.
  argon2d(0),

  /// Argon2id variant.
  argon2id(2);

  const Argon2Type(this.value);

  /// Numeric representation of the Argon2 variant.
  final int value;
}

/// Argon2 algorithm versions.
///
/// `v13` is the recommended version for modern use.
enum Argon2Version {
  /// Argon2 version 1.0.
  v10(0x10),

  /// Argon2 version 1.3.
  v13(0x13);

  const Argon2Version(this.value);

  /// Numeric representation of the Argon2 version.
  final int value;
}

/// Argon2 key derivation algorithm.
///
/// `Argon2` is the shared public contract for Argon2 implementations.
/// Concrete implementations include Argon2Dart and Argon2Ffi.
abstract class Argon2 {
  /// Derives a key from [password].
  Uint8List convert(List<int> password);
}
