import 'dart:typed_data';

import '../chacha20.dart';
import '../stream_cipher.dart';

/// Pure Dart ChaCha20 implementation (RFC 7539).
///
/// Uses a 256-bit key, 96-bit nonce, and 32-bit block counter.
class ChaCha20Dart extends ChaCha20 {
  final Uint8List _key;

  /// Creates a Dart [ChaCha20] instance with the given 32-byte [key].
  ChaCha20Dart({required Uint8List key}) : _key = key;

  @override
  Uint8List transform({
    required Uint8List data,
    required Uint8List nonce,
    int counter = 0,
  }) {
    final state = Uint32List(16);

    // Build initial state: constants | key | counter | nonce
    state[0] = 0x61707865; // "expa"
    state[1] = 0x3320646e; // "nd 3"
    state[2] = 0x79622d32; // "2-by"
    state[3] = 0x6b206574; // "te k"
    for (var i = 0; i < 8; i++) {
      state[4 + i] = StreamCipher.loadLE(_key, i * 4);
    }
    state[12] = counter;
    state[13] = StreamCipher.loadLE(nonce, 0);
    state[14] = StreamCipher.loadLE(nonce, 4);
    state[15] = StreamCipher.loadLE(nonce, 8);

    return StreamCipher.processStream(
      data: data,
      state: state,
      generateBlock: _block,
      incrementCounter: (state) {
        state[12] = StreamCipher.add32(state[12], 1);
      },
    );
  }

  /// Computes one ChaCha20 block: 20 rounds on [state], adds original state.
  static void _block(Uint32List state, Uint32List out) {
    // Copy state into working registers
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

    // 10 double rounds (= 20 rounds)
    // All additions masked to 32 bits (Dart ints are 64-bit).
    for (var i = 0; i < 10; i++) {
      // Column rounds
      x0 = StreamCipher.add32(x0, x4);
      x12 ^= x0;
      x12 = StreamCipher.rotl(x12, 16);
      x8 = StreamCipher.add32(x8, x12);
      x4 ^= x8;
      x4 = StreamCipher.rotl(x4, 12);
      x0 = StreamCipher.add32(x0, x4);
      x12 ^= x0;
      x12 = StreamCipher.rotl(x12, 8);
      x8 = StreamCipher.add32(x8, x12);
      x4 ^= x8;
      x4 = StreamCipher.rotl(x4, 7);

      x1 = StreamCipher.add32(x1, x5);
      x13 ^= x1;
      x13 = StreamCipher.rotl(x13, 16);
      x9 = StreamCipher.add32(x9, x13);
      x5 ^= x9;
      x5 = StreamCipher.rotl(x5, 12);
      x1 = StreamCipher.add32(x1, x5);
      x13 ^= x1;
      x13 = StreamCipher.rotl(x13, 8);
      x9 = StreamCipher.add32(x9, x13);
      x5 ^= x9;
      x5 = StreamCipher.rotl(x5, 7);

      x2 = StreamCipher.add32(x2, x6);
      x14 ^= x2;
      x14 = StreamCipher.rotl(x14, 16);
      x10 = StreamCipher.add32(x10, x14);
      x6 ^= x10;
      x6 = StreamCipher.rotl(x6, 12);
      x2 = StreamCipher.add32(x2, x6);
      x14 ^= x2;
      x14 = StreamCipher.rotl(x14, 8);
      x10 = StreamCipher.add32(x10, x14);
      x6 ^= x10;
      x6 = StreamCipher.rotl(x6, 7);

      x3 = StreamCipher.add32(x3, x7);
      x15 ^= x3;
      x15 = StreamCipher.rotl(x15, 16);
      x11 = StreamCipher.add32(x11, x15);
      x7 ^= x11;
      x7 = StreamCipher.rotl(x7, 12);
      x3 = StreamCipher.add32(x3, x7);
      x15 ^= x3;
      x15 = StreamCipher.rotl(x15, 8);
      x11 = StreamCipher.add32(x11, x15);
      x7 ^= x11;
      x7 = StreamCipher.rotl(x7, 7);

      // Diagonal rounds
      x0 = StreamCipher.add32(x0, x5);
      x15 ^= x0;
      x15 = StreamCipher.rotl(x15, 16);
      x10 = StreamCipher.add32(x10, x15);
      x5 ^= x10;
      x5 = StreamCipher.rotl(x5, 12);
      x0 = StreamCipher.add32(x0, x5);
      x15 ^= x0;
      x15 = StreamCipher.rotl(x15, 8);
      x10 = StreamCipher.add32(x10, x15);
      x5 ^= x10;
      x5 = StreamCipher.rotl(x5, 7);

      x1 = StreamCipher.add32(x1, x6);
      x12 ^= x1;
      x12 = StreamCipher.rotl(x12, 16);
      x11 = StreamCipher.add32(x11, x12);
      x6 ^= x11;
      x6 = StreamCipher.rotl(x6, 12);
      x1 = StreamCipher.add32(x1, x6);
      x12 ^= x1;
      x12 = StreamCipher.rotl(x12, 8);
      x11 = StreamCipher.add32(x11, x12);
      x6 ^= x11;
      x6 = StreamCipher.rotl(x6, 7);

      x2 = StreamCipher.add32(x2, x7);
      x13 ^= x2;
      x13 = StreamCipher.rotl(x13, 16);
      x8 = StreamCipher.add32(x8, x13);
      x7 ^= x8;
      x7 = StreamCipher.rotl(x7, 12);
      x2 = StreamCipher.add32(x2, x7);
      x13 ^= x2;
      x13 = StreamCipher.rotl(x13, 8);
      x8 = StreamCipher.add32(x8, x13);
      x7 ^= x8;
      x7 = StreamCipher.rotl(x7, 7);

      x3 = StreamCipher.add32(x3, x4);
      x14 ^= x3;
      x14 = StreamCipher.rotl(x14, 16);
      x9 = StreamCipher.add32(x9, x14);
      x4 ^= x9;
      x4 = StreamCipher.rotl(x4, 12);
      x3 = StreamCipher.add32(x3, x4);
      x14 ^= x3;
      x14 = StreamCipher.rotl(x14, 8);
      x9 = StreamCipher.add32(x9, x14);
      x4 ^= x9;
      x4 = StreamCipher.rotl(x4, 7);
    }

    // Add original state (mod 2^32)
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
