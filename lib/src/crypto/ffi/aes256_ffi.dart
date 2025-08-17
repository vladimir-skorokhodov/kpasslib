import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../aes.dart';

/// FFI signature for `aes256_transform_block`.
typedef Aes256TransformBlockC = Void Function(
    Pointer<Uint8> data, Pointer<Uint8> key, Uint64 rounds);

/// Dart signature for `aes256_transform_block`.
typedef Aes256TransformBlockDart = void Function(
    Pointer<Uint8> data, Pointer<Uint8> key, int rounds);

/// FFI signature for `aes256_cbc_encrypt` / `aes256_cbc_decrypt`.
typedef Aes256CbcC = Void Function(
  Pointer<Uint8> data,
  Uint32 dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> iv,
);

/// Dart signature for `aes256_cbc_encrypt` / `aes256_cbc_decrypt`.
typedef Aes256CbcDart = void Function(
  Pointer<Uint8> data,
  int dataLen,
  Pointer<Uint8> key,
  Pointer<Uint8> iv,
);

/// FFI [Aes256] implementation.
///
/// Created by `CryptoFfi.createAes256`.
class Aes256Ffi extends Aes256 {
  final Aes256TransformBlockDart _transformFn;
  final Aes256CbcDart _encryptCbcFn;
  final Aes256CbcDart _decryptCbcFn;
  final Uint8List _key;

  /// Wraps native AES-256 functions with the given [key].
  Aes256Ffi({
    required Aes256TransformBlockDart transformFn,
    required Aes256CbcDart encryptCbcFn,
    required Aes256CbcDart decryptCbcFn,
    required Uint8List key,
  })  : _transformFn = transformFn,
        _encryptCbcFn = encryptCbcFn,
        _decryptCbcFn = decryptCbcFn,
        _key = key;

  @override
  void transformBlock({required Uint8List data, required int rounds}) {
    final pData = malloc<Uint8>(16);
    final pKey = malloc<Uint8>(32);
    try {
      pData.asTypedList(16).setAll(0, data);
      pKey.asTypedList(32).setAll(0, _key);
      _transformFn(pData, pKey, rounds);
      data.setAll(0, pData.asTypedList(16));
    } finally {
      malloc.free(pData);
      malloc.free(pKey);
    }
  }

  @override
  Uint8List encryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  }) {
    final input = padding ? _pad(data) : data;
    return _cbcTransform(_encryptCbcFn, input, iv);
  }

  @override
  Uint8List decryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  }) {
    final decrypted = _cbcTransform(_decryptCbcFn, data, iv);
    if (!padding) return decrypted;
    final padLen = decrypted.last;
    return Uint8List.sublistView(decrypted, 0, decrypted.length - padLen);
  }

  Uint8List _cbcTransform(Aes256CbcDart fn, Uint8List data, Uint8List iv) {
    final dataLen = data.length;
    final pData = malloc<Uint8>(dataLen);
    final pKey = malloc<Uint8>(32);
    final pIv = malloc<Uint8>(16);
    try {
      pData.asTypedList(dataLen).setAll(0, data);
      pKey.asTypedList(32).setAll(0, _key);
      pIv.asTypedList(16).setAll(0, iv);
      fn(pData, dataLen, pKey, pIv);
      return Uint8List.fromList(pData.asTypedList(dataLen));
    } finally {
      malloc.free(pData);
      malloc.free(pKey);
      malloc.free(pIv);
    }
  }

  static Uint8List _pad(Uint8List data) {
    final padLen = 16 - (data.length % 16);
    return Uint8List(data.length + padLen)
      ..setAll(0, data)
      ..fillRange(data.length, data.length + padLen, padLen);
  }
}
