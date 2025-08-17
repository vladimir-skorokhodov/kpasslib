import 'dart:typed_data';

import '../salsa20.dart';
import '../stream_cipher.dart';

/// Pure Dart Salsa20 implementation (RFC 7532).
class Salsa20Dart extends Salsa20 {
  final Uint8List _key;

  /// Creates a Dart [Salsa20] instance with the given 32-byte [key].
  Salsa20Dart({required Uint8List key}) : _key = key;

  @override
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  }) {
    assert(_key.length == 32);
    assert(nonce.length == 8);

    final state = Uint32List(16);

    state[0] = 0x61707865; // "expa"
    state[1] = StreamCipher.loadLE(_key, 0);
    state[2] = StreamCipher.loadLE(_key, 4);
    state[3] = StreamCipher.loadLE(_key, 8);
    state[4] = StreamCipher.loadLE(_key, 12);
    state[5] = 0x3320646e; // "nd 3"
    state[6] = StreamCipher.loadLE(nonce, 0);
    state[7] = StreamCipher.loadLE(nonce, 4);
    state[8] = counter & StreamCipher.mask;
    state[9] = (counter >> 32) & StreamCipher.mask;
    state[10] = 0x79622d32; // "2-by"
    state[11] = StreamCipher.loadLE(_key, 16);
    state[12] = StreamCipher.loadLE(_key, 20);
    state[13] = StreamCipher.loadLE(_key, 24);
    state[14] = StreamCipher.loadLE(_key, 28);
    state[15] = 0x6b206574; // "te k"

    return StreamCipher.processStream(
      data: data,
      state: state,
      generateBlock: _block,
      incrementCounter: (state) {
        state[8] = StreamCipher.add32(state[8], 1);
        if (state[8] == 0) {
          state[9] = StreamCipher.add32(state[9], 1);
        }
      },
    );
  }

  static void _block(Uint32List state, Uint32List out) {
    var x0 = state[0],
        x1 = state[1],
        x2 = state[2],
        x3 = state[3],
        x4 = state[4],
        x5 = state[5],
        x6 = state[6],
        x7 = state[7],
        x8 = state[8],
        x9 = state[9],
        x10 = state[10],
        x11 = state[11],
        x12 = state[12],
        x13 = state[13],
        x14 = state[14],
        x15 = state[15];

    for (var i = 0; i < 10; i++) {
      // Column rounds
      x4 ^= StreamCipher.add32Rotl(x0, x12, 7);
      x8 ^= StreamCipher.add32Rotl(x4, x0, 9);
      x12 ^= StreamCipher.add32Rotl(x8, x4, 13);
      x0 ^= StreamCipher.add32Rotl(x12, x8, 18);

      x9 ^= StreamCipher.add32Rotl(x5, x1, 7);
      x13 ^= StreamCipher.add32Rotl(x9, x5, 9);
      x1 ^= StreamCipher.add32Rotl(x13, x9, 13);
      x5 ^= StreamCipher.add32Rotl(x1, x13, 18);

      x14 ^= StreamCipher.add32Rotl(x10, x6, 7);
      x2 ^= StreamCipher.add32Rotl(x14, x10, 9);
      x6 ^= StreamCipher.add32Rotl(x2, x14, 13);
      x10 ^= StreamCipher.add32Rotl(x6, x2, 18);

      x3 ^= StreamCipher.add32Rotl(x15, x11, 7);
      x7 ^= StreamCipher.add32Rotl(x3, x15, 9);
      x11 ^= StreamCipher.add32Rotl(x7, x3, 13);
      x15 ^= StreamCipher.add32Rotl(x11, x7, 18);

      // Row rounds
      x1 ^= StreamCipher.add32Rotl(x0, x3, 7);
      x2 ^= StreamCipher.add32Rotl(x1, x0, 9);
      x3 ^= StreamCipher.add32Rotl(x2, x1, 13);
      x0 ^= StreamCipher.add32Rotl(x3, x2, 18);

      x6 ^= StreamCipher.add32Rotl(x5, x4, 7);
      x7 ^= StreamCipher.add32Rotl(x6, x5, 9);
      x4 ^= StreamCipher.add32Rotl(x7, x6, 13);
      x5 ^= StreamCipher.add32Rotl(x4, x7, 18);

      x11 ^= StreamCipher.add32Rotl(x10, x9, 7);
      x8 ^= StreamCipher.add32Rotl(x11, x10, 9);
      x9 ^= StreamCipher.add32Rotl(x8, x11, 13);
      x10 ^= StreamCipher.add32Rotl(x9, x8, 18);

      x12 ^= StreamCipher.add32Rotl(x15, x14, 7);
      x13 ^= StreamCipher.add32Rotl(x12, x15, 9);
      x14 ^= StreamCipher.add32Rotl(x13, x12, 13);
      x15 ^= StreamCipher.add32Rotl(x14, x13, 18);
    }

    out[0] = StreamCipher.add32(x0, state[0]);
    out[1] = StreamCipher.add32(x1, state[1]);
    out[2] = StreamCipher.add32(x2, state[2]);
    out[3] = StreamCipher.add32(x3, state[3]);
    out[4] = StreamCipher.add32(x4, state[4]);
    out[5] = StreamCipher.add32(x5, state[5]);
    out[6] = StreamCipher.add32(x6, state[6]);
    out[7] = StreamCipher.add32(x7, state[7]);
    out[8] = StreamCipher.add32(x8, state[8]);
    out[9] = StreamCipher.add32(x9, state[9]);
    out[10] = StreamCipher.add32(x10, state[10]);
    out[11] = StreamCipher.add32(x11, state[11]);
    out[12] = StreamCipher.add32(x12, state[12]);
    out[13] = StreamCipher.add32(x13, state[13]);
    out[14] = StreamCipher.add32(x14, state[14]);
    out[15] = StreamCipher.add32(x15, state[15]);
  }
}
