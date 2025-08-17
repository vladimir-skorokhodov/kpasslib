import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../chacha20.dart';

/// FFI signature for `chacha20_transform`.
typedef ChaCha20TransformC = Void Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> nonce,
  Uint32 counter,
);

/// Dart signature for `chacha20_transform`.
typedef ChaCha20TransformDart = void Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> nonce,
  int counter,
);

/// FFI [ChaCha20] implementation.
///
/// Created by `CryptoFfi.createChaCha20`.
class ChaCha20Ffi extends ChaCha20 {
  final ChaCha20TransformDart _transformFn;
  final Uint8List _key;

  /// Creates a FFI ChaCha20 cipher using the provided FFI function and key.
  ///
  /// [transformFn] is the FFI binding to the native `chacha20_transform` function.
  /// [key] is a 32-byte ChaCha20 key.
  ChaCha20Ffi({
    required ChaCha20TransformDart transformFn,
    required Uint8List key,
  })  : _transformFn = transformFn,
        _key = key;

  @override
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  }) {
    final dataLen = data.length;
    final pData = malloc<Uint8>(dataLen);
    final pKey = malloc<Uint8>(32);
    final pNonce = malloc<Uint8>(12);
    try {
      pData.asTypedList(dataLen).setAll(0, data);
      pKey.asTypedList(32).setAll(0, _key);
      pNonce.asTypedList(12).setAll(0, nonce);
      _transformFn(pData, dataLen, pKey, pNonce, counter);
      return Uint8List.fromList(pData.asTypedList(dataLen));
    } finally {
      malloc.free(pData);
      malloc.free(pKey);
      malloc.free(pNonce);
    }
  }
}
