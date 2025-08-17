import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../salsa20.dart';

/// FFI signature for `salsa20_transform`.
typedef Salsa20TransformC = Void Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> nonce,
  Uint64 counter,
);

/// Dart signature for `salsa20_transform`.
typedef Salsa20TransformDart = void Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> nonce,
  int counter,
);

/// FFI [Salsa20] implementation.
class Salsa20Ffi extends Salsa20 {
  final Salsa20TransformDart _transformFn;
  final Uint8List _key;

  /// Creates a FFI Salsa20 cipher with the provided FFI function and key.
  Salsa20Ffi({
    required Salsa20TransformDart transformFn,
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
    final pNonce = malloc<Uint8>(8);
    try {
      pData.asTypedList(dataLen).setAll(0, data);
      pKey.asTypedList(32).setAll(0, _key);
      pNonce.asTypedList(8).setAll(0, nonce);
      _transformFn(pData, dataLen, pKey, pNonce, counter);
      return Uint8List.fromList(pData.asTypedList(dataLen));
    } finally {
      malloc.free(pData);
      malloc.free(pKey);
      malloc.free(pNonce);
    }
  }
}
