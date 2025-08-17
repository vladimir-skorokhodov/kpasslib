import 'dart:typed_data';

/// BLAKE2b hash implementation used internally by Argon2.
///
/// This class is exposed only to package internals and provides the
/// byte-level hashing operations required by the Argon2 reference flow.
class Blake2bHash {
  static const int _r1 = 32;
  static const int _r2 = 24;
  static const int _r3 = 16;
  static const int _r4 = 63;
  static const int _blockBytes = 128;
  static const int _mask64 = 0xFFFFFFFFFFFFFFFF;
  static const int _seed0 = 0x6A09E667F3BCC908;
  static const int _seed1 = 0xBB67AE8584CAA73B;
  static const int _seed2 = 0x3C6EF372FE94F82B;
  static const int _seed3 = 0xA54FF53A5F1D36F1;
  static const int _seed4 = 0x510E527FADE682D1;
  static const int _seed5 = 0x9B05688C2B3E6C1F;
  static const int _seed6 = 0x1F83D9ABFB41BD6B;
  static const int _seed7 = 0x5BE0CD19137E2179;

  static const List<List<int>> _sigma = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
    [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
    [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
    [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
    [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
    [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
    [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
    [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
    [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
  ];

  /// Digest length in bytes.
  final int hashLength;

  /// Optional keyed hashing key.
  final List<int>? key;

  /// Optional salt value.
  final List<int>? salt;

  /// Optional personalization value.
  final List<int>? aad;

  final Uint8List _buffer = Uint8List(_blockBytes);
  final Uint64List _state = Uint64List(8);

  int _messageLength = 0;
  int _pos = 0;

  /// Creates a new BLAKE2b hash context.
  ///
  /// [hashLength] specifies the number of output bytes.
  /// Optional [key], [salt], and [aad] values are supported by the
  /// Argon2 reference implementation.
  Blake2bHash(
    this.hashLength, {
    this.key,
    this.salt,
    this.aad,
  }) {
    if (hashLength < 1 || hashLength > 64) {
      throw ArgumentError('The digest size must be between 1 and 64');
    }
    if (salt != null && salt!.isNotEmpty && salt!.length != 16) {
      throw ArgumentError('The valid length of salt is 16 bytes');
    }
    if (aad != null && aad!.isNotEmpty && aad!.length != 16) {
      throw ArgumentError('The valid length of personalization is 16 bytes');
    }
    if (key != null && key!.length > 64) {
      throw ArgumentError('The key should not be greater than 64 bytes');
    }
    reset();
  }

  /// Resets the hash context back to its initial state.
  void reset() {
    _state[0] = _seed0 ^ 0x01010000 ^ hashLength;
    _state[1] = _seed1;
    _state[2] = _seed2;
    _state[3] = _seed3;
    _state[4] = _seed4;
    _state[5] = _seed5;
    _state[6] = _seed6;
    _state[7] = _seed7;

    if (key != null && key!.isNotEmpty) {
      _state[0] ^= key!.length << 8;
    }

    if (salt != null && salt!.isNotEmpty) {
      for (int i = 0, p = 0; i < 8; i++, p += 8) {
        _state[4] ^= (salt![i] & 0xFF) << p;
      }
      for (int i = 8, p = 0; i < 16; i++, p += 8) {
        _state[5] ^= (salt![i] & 0xFF) << p;
      }
    }

    if (aad != null && aad!.isNotEmpty) {
      for (int i = 0, p = 0; i < 8; i++, p += 8) {
        _state[6] ^= (aad![i] & 0xFF) << p;
      }
      for (int i = 8, p = 0; i < 16; i++, p += 8) {
        _state[7] ^= (aad![i] & 0xFF) << p;
      }
    }

    _buffer.fillRange(0, _blockBytes, 0);
    _pos = 0;
    _messageLength = 0;

    if (key != null && key!.isNotEmpty) {
      _buffer.setAll(0, key!);
      _pos = _blockBytes;
      _messageLength = _blockBytes;
    }
  }

  /// Adds bytes to the hash input stream.
  void add(List<int> input) {
    for (var byte in input) {
      _buffer[_pos++] = byte;
      _messageLength++;
      if (_pos == _blockBytes) {
        _update(_buffer, false);
        _pos = 0;
      }
    }
  }

  /// Appends a 32-bit little-endian integer to the hash input.
  void addUint32(int value) {
    add([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }

  /// Finalizes the hash and returns the digest bytes.
  Uint8List digest() {
    while (_pos < _blockBytes) {
      _buffer[_pos++] = 0;
    }
    _update(_buffer, true);
    return Uint8List.view(_state.buffer).sublist(0, hashLength);
  }

  Uint64List _loadMessageWords(Uint8List block) {
    final data = ByteData.sublistView(block);
    final words = Uint64List(16);
    for (int i = 0; i < 16; i++) {
      words[i] = data.getUint64(i * 8, Endian.little);
    }
    return words;
  }

  void _g(
      Uint64List v, Uint64List m, int a, int b, int c, int d, int x, int y) {
    v[a] = _add64(v[a], v[b], m[x]);
    v[d] = _rotr(v[d] ^ v[a], _r1);
    v[c] = _add64(v[c], v[d]);
    v[b] = _rotr(v[b] ^ v[c], _r2);
    v[a] = _add64(v[a], v[b], m[y]);
    v[d] = _rotr(v[d] ^ v[a], _r3);
    v[c] = _add64(v[c], v[d]);
    v[b] = _rotr(v[b] ^ v[c], _r4);
  }

  void _applyBlake2bRound(Uint64List v, Uint64List m, List<int> sigmaRow) {
    _g(v, m, 0, 4, 8, 12, sigmaRow[0], sigmaRow[1]);
    _g(v, m, 1, 5, 9, 13, sigmaRow[2], sigmaRow[3]);
    _g(v, m, 2, 6, 10, 14, sigmaRow[4], sigmaRow[5]);
    _g(v, m, 3, 7, 11, 15, sigmaRow[6], sigmaRow[7]);

    _g(v, m, 0, 5, 10, 15, sigmaRow[8], sigmaRow[9]);
    _g(v, m, 1, 6, 11, 12, sigmaRow[10], sigmaRow[11]);
    _g(v, m, 2, 7, 8, 13, sigmaRow[12], sigmaRow[13]);
    _g(v, m, 3, 4, 9, 14, sigmaRow[14], sigmaRow[15]);
  }

  void _update(Uint8List block, bool last) {
    final m = _loadMessageWords(block);
    final v = Uint64List(16);

    v.setRange(0, 8, _state);
    v[8] = _seed0;
    v[9] = _seed1;
    v[10] = _seed2;
    v[11] = _seed3;
    v[12] = _seed4 ^ _messageLength;
    v[13] = _seed5;
    v[14] = _seed6;
    v[15] = _seed7;

    if (last) {
      v[14] = (~v[14]) & _mask64;
    }

    for (int i = 0; i < 12; i++) {
      _applyBlake2bRound(v, m, _sigma[i]);
    }

    for (int i = 0; i < 8; i++) {
      _state[i] ^= v[i] ^ v[i + 8];
    }
  }

  static int _rotr(int x, int n) {
    x &= _mask64;
    return ((x >>> n) | (x << (64 - n))) & _mask64;
  }

  static int _add64(int a, int b, [int c = 0]) {
    return (a + b + c) & _mask64;
  }
}
