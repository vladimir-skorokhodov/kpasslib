import 'dart:typed_data';

import '../argon2.dart';
import '../blake2b.dart';

/// Pure Dart [Argon2] implementation.
class Argon2Dart extends Argon2 {
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

  /// Creates a Dart-backed Argon2 instance.
  Argon2Dart({
    this.type = Argon2Type.argon2id,
    this.version = Argon2Version.v13,
    required this.parallelism,
    required this.memorySizeKB,
    required this.iterations,
    required List<int> salt,
  }) : salt = Uint8List.fromList(salt);

  @override
  Uint8List convert(List<int> password) {
    final ctx = _Argon2Context(
      type: type,
      version: version,
      parallelism: parallelism,
      memorySizeKB: memorySizeKB,
      iterations: iterations,
      salt: salt,
    );
    return _Argon2Internal(ctx).convert(password);
  }
}

/// Internal Argon2 implementation details used by [Argon2Dart].
class _Argon2Context {
  static const int _defaultHashLength = 32;
  static const int _slices = 4;
  static const int _minParallelism = 1;
  static const int _maxParallelism = 0x7FFF;
  static const int _minDigestSize = 4;
  static const int _maxDigestSize = 0x3FFFFFF;
  static const int _minIterations = 1;
  static const int _maxIterations = 0x3FFFFFF;
  static const int _maxMemory = 0x3FFFFFF;
  static const int _minSaltSize = 8;
  static const int _maxSaltSize = 0x3FFFFFF;

  final Argon2Type type;
  final Argon2Version version;
  final int lanes;
  final int hashLength;
  final int memorySizeKB;
  final int passes;
  final List<int> salt;
  final int slices;
  final int midSlice;
  final int segments;
  final int columns;
  final int blocks;

  const _Argon2Context._({
    required this.type,
    required this.version,
    required this.lanes,
    required this.hashLength,
    required this.memorySizeKB,
    required this.passes,
    required this.salt,
    required this.slices,
    required this.midSlice,
    required this.segments,
    required this.columns,
    required this.blocks,
  });

  factory _Argon2Context({
    required int iterations,
    required int parallelism,
    required int memorySizeKB,
    required List<int> salt,
    Argon2Version version = Argon2Version.v13,
    Argon2Type type = Argon2Type.argon2id,
  }) {
    const hashLength = _defaultHashLength;
    if (hashLength < _minDigestSize) {
      throw ArgumentError('The tag length must be at least $_minDigestSize');
    }
    if (hashLength > _maxDigestSize) {
      throw ArgumentError('The tag length must be at most $_maxDigestSize');
    }
    if (parallelism < _minParallelism) {
      throw ArgumentError('The parallelism must be at least $_minParallelism');
    }
    if (parallelism > _maxParallelism) {
      throw ArgumentError('The parallelism must be at most $_maxParallelism');
    }
    if (iterations < _minIterations) {
      throw ArgumentError('The iterations must be at least $_minIterations');
    }
    if (iterations > _maxIterations) {
      throw ArgumentError('The iterations must be at most $_maxIterations');
    }
    if (memorySizeKB < (parallelism << 3)) {
      throw ArgumentError('The memory size must be at least 8 * parallelism');
    }
    if (memorySizeKB > _maxMemory) {
      throw ArgumentError('The memorySizeKB must be at most $_maxMemory');
    }
    if (salt.length < _minSaltSize) {
      throw ArgumentError('The salt must be at least $_minSaltSize bytes long');
    }
    if (salt.length > _maxSaltSize) {
      throw ArgumentError('The salt must be at most $_maxSaltSize bytes long');
    }

    final int segments = memorySizeKB ~/ (_slices * parallelism);
    final int columns = _slices * segments;
    final int blocks = parallelism * _slices * segments;

    return _Argon2Context._(
      salt: salt,
      version: version,
      type: type,
      hashLength: hashLength,
      passes: iterations,
      lanes: parallelism,
      memorySizeKB: memorySizeKB,
      slices: _slices,
      segments: segments,
      columns: columns,
      blocks: blocks,
      midSlice: _slices ~/ 2,
    );
  }
}

class _Argon2Internal {
  static const int _mask32 = 0xFFFFFFFF;

  final _Argon2Context ctx;
  final Uint8List _hash0 = Uint8List(64 + 8);
  final Uint64List _blockR = Uint64List(128);
  final Uint64List _blockT = Uint64List(128);
  final Uint64List _input = Uint64List(128);
  final Uint64List _address = Uint64List(128);

  late final Uint8List _digest = Uint8List(ctx.hashLength);
  late final Uint64List _memory = Uint64List(ctx.blocks << 7);

  _Argon2Internal(this.ctx);

  @pragma('vm:prefer-inline')
  static int _mul32(int a, int b) => (a & _mask32) * (b & _mask32);

  @pragma('vm:prefer-inline')
  static int _rotr(int x, int n) => (x >>> n) ^ (x << (64 - n));

  static void _expandHash(
    int digestSize,
    Uint8List message,
    Uint8List output,
    int offset,
  ) {
    int i;

    if (digestSize <= 64) {
      final blake2b = Blake2bHash(digestSize);
      blake2b.addUint32(digestSize);
      blake2b.add(message);
      var hash = blake2b.digest();
      for (i = 0; i < digestSize; ++i, offset++) {
        output[offset] = hash[i];
      }
      return;
    }

    final blake2b = Blake2bHash(64);
    blake2b.addUint32(digestSize);
    blake2b.add(message);
    var hash = blake2b.digest();

    for (i = 0; i < 32; ++i, ++offset) {
      output[offset] = hash[i];
    }

    for (var j = digestSize - 32; j > 64; j -= 32) {
      blake2b.reset();
      blake2b.add(hash);
      hash = blake2b.digest();
      for (i = 0; i < 32; ++i, ++offset) {
        output[offset] = hash[i];
      }
    }

    blake2b.reset();
    blake2b.add(hash);
    hash = blake2b.digest();
    for (i = 0; i < digestSize - 32 && i < hash.length; ++i, ++offset) {
      output[offset] = hash[i];
    }
  }

  static void _blake2bMixer(
    Uint64List v,
    int i0,
    int i1,
    int i2,
    int i3,
    int i4,
    int i5,
    int i6,
    int i7,
    int i8,
    int i9,
    int i10,
    int i11,
    int i12,
    int i13,
    int i14,
    int i15,
  ) {
    int v0 = v[i0];
    int v1 = v[i1];
    int v2 = v[i2];
    int v3 = v[i3];
    int v4 = v[i4];
    int v5 = v[i5];
    int v6 = v[i6];
    int v7 = v[i7];
    int v8 = v[i8];
    int v9 = v[i9];
    int v10 = v[i10];
    int v11 = v[i11];
    int v12 = v[i12];
    int v13 = v[i13];
    int v14 = v[i14];
    int v15 = v[i15];

    v0 += v4 + (_mul32(v0, v4) << 1);
    v12 = _rotr(v12 ^ v0, 32);
    v8 += v12 + (_mul32(v8, v12) << 1);
    v4 = _rotr(v4 ^ v8, 24);
    v0 += v4 + (_mul32(v0, v4) << 1);
    v12 = _rotr(v12 ^ v0, 16);
    v8 += v12 + (_mul32(v8, v12) << 1);
    v4 = _rotr(v4 ^ v8, 63);

    v1 += v5 + (_mul32(v1, v5) << 1);
    v13 = _rotr(v13 ^ v1, 32);
    v9 += v13 + (_mul32(v9, v13) << 1);
    v5 = _rotr(v5 ^ v9, 24);
    v1 += v5 + (_mul32(v1, v5) << 1);
    v13 = _rotr(v13 ^ v1, 16);
    v9 += v13 + (_mul32(v9, v13) << 1);
    v5 = _rotr(v5 ^ v9, 63);

    v2 += v6 + (_mul32(v2, v6) << 1);
    v14 = _rotr(v14 ^ v2, 32);
    v10 += v14 + (_mul32(v10, v14) << 1);
    v6 = _rotr(v6 ^ v10, 24);
    v2 += v6 + (_mul32(v2, v6) << 1);
    v14 = _rotr(v14 ^ v2, 16);
    v10 += v14 + (_mul32(v10, v14) << 1);
    v6 = _rotr(v6 ^ v10, 63);

    v3 += v7 + (_mul32(v3, v7) << 1);
    v15 = _rotr(v15 ^ v3, 32);
    v11 += v15 + (_mul32(v11, v15) << 1);
    v7 = _rotr(v7 ^ v11, 24);
    v3 += v7 + (_mul32(v3, v7) << 1);
    v15 = _rotr(v15 ^ v3, 16);
    v11 += v15 + (_mul32(v11, v15) << 1);
    v7 = _rotr(v7 ^ v11, 63);

    v0 += v5 + (_mul32(v0, v5) << 1);
    v15 = _rotr(v15 ^ v0, 32);
    v10 += v15 + (_mul32(v10, v15) << 1);
    v5 = _rotr(v5 ^ v10, 24);
    v0 += v5 + (_mul32(v0, v5) << 1);
    v15 = _rotr(v15 ^ v0, 16);
    v10 += v15 + (_mul32(v10, v15) << 1);
    v5 = _rotr(v5 ^ v10, 63);

    v1 += v6 + (_mul32(v1, v6) << 1);
    v12 = _rotr(v12 ^ v1, 32);
    v11 += v12 + (_mul32(v11, v12) << 1);
    v6 = _rotr(v6 ^ v11, 24);
    v1 += v6 + (_mul32(v1, v6) << 1);
    v12 = _rotr(v12 ^ v1, 16);
    v11 += v12 + (_mul32(v11, v12) << 1);
    v6 = _rotr(v6 ^ v11, 63);

    v2 += v7 + (_mul32(v2, v7) << 1);
    v13 = _rotr(v13 ^ v2, 32);
    v8 += v13 + (_mul32(v8, v13) << 1);
    v7 = _rotr(v7 ^ v8, 24);
    v2 += v7 + (_mul32(v2, v7) << 1);
    v13 = _rotr(v13 ^ v2, 16);
    v8 += v13 + (_mul32(v8, v13) << 1);
    v7 = _rotr(v7 ^ v8, 63);

    v3 += v4 + (_mul32(v3, v4) << 1);
    v14 = _rotr(v14 ^ v3, 32);
    v9 += v14 + (_mul32(v9, v14) << 1);
    v4 = _rotr(v4 ^ v9, 24);
    v3 += v4 + (_mul32(v3, v4) << 1);
    v14 = _rotr(v14 ^ v3, 16);
    v9 += v14 + (_mul32(v9, v14) << 1);
    v4 = _rotr(v4 ^ v9, 63);

    v[i0] = v0;
    v[i1] = v1;
    v[i2] = v2;
    v[i3] = v3;
    v[i4] = v4;
    v[i5] = v5;
    v[i6] = v6;
    v[i7] = v7;
    v[i8] = v8;
    v[i9] = v9;
    v[i10] = v10;
    v[i11] = v11;
    v[i12] = v12;
    v[i13] = v13;
    v[i14] = v14;
    v[i15] = v15;
  }

  static void _applyBlake2bRounds(Uint64List state) {
    for (int j = 0; j < 128; j += 16) {
      _blake2bMixer(
        state,
        j,
        j + 1,
        j + 2,
        j + 3,
        j + 4,
        j + 5,
        j + 6,
        j + 7,
        j + 8,
        j + 9,
        j + 10,
        j + 11,
        j + 12,
        j + 13,
        j + 14,
        j + 15,
      );
    }

    for (int j = 0; j < 16; j += 2) {
      _blake2bMixer(
        state,
        j,
        j + 1,
        j + 16,
        j + 17,
        j + 32,
        j + 33,
        j + 48,
        j + 49,
        j + 64,
        j + 65,
        j + 80,
        j + 81,
        j + 96,
        j + 97,
        j + 112,
        j + 113,
      );
    }
  }

  Uint8List convert(List<int> password) {
    final ctx = this.ctx;
    final hash0_32 = Uint32List.view(_hash0.buffer);
    final memoryBytes = Uint8List.view(_memory.buffer);
    final laneBytes = ctx.columns << 10;

    _initialHash(_hash0, password);

    hash0_32[16] = 0;
    for (var lane = 0, offset = 0;
        lane < ctx.lanes;
        lane++, offset += laneBytes) {
      hash0_32[17] = lane;
      _expandHash(1024, _hash0, memoryBytes, offset);
    }

    hash0_32[16] = 1;
    for (var lane = 0, offset = 1024;
        lane < ctx.lanes;
        lane++, offset += laneBytes) {
      hash0_32[17] = lane;
      _expandHash(1024, _hash0, memoryBytes, offset);
    }

    for (var pass = 0; pass < ctx.passes; pass++) {
      for (var slice = 0; slice < ctx.slices; slice++) {
        for (var lane = 0; lane < ctx.lanes; lane++) {
          _fillSegment(pass, slice, lane);
        }
      }
    }

    var offset = laneBytes - 1024;
    final block = Uint8List.view(memoryBytes.buffer, offset, 1024);
    for (var lane = 1; lane < ctx.lanes; lane++) {
      offset += laneBytes;
      for (var i = 0; i < 1024; i++) {
        block[i] ^= memoryBytes[offset + i];
      }
    }

    _expandHash(ctx.hashLength, block, _digest, 0);
    return _digest;
  }

  void _initialHash(Uint8List hash0, List<int> password) {
    var blake2b = Blake2bHash(64);
    blake2b.addUint32(ctx.lanes);
    blake2b.addUint32(ctx.hashLength);
    blake2b.addUint32(ctx.memorySizeKB);
    blake2b.addUint32(ctx.passes);
    blake2b.addUint32(ctx.version.value);
    blake2b.addUint32(ctx.type.value);
    blake2b.addUint32(password.length);
    blake2b.add(password);
    blake2b.addUint32(ctx.salt.length);
    blake2b.add(ctx.salt);
    blake2b.addUint32(0);
    blake2b.addUint32(0);

    var hash = blake2b.digest();
    for (int i = 0; i < 64; ++i) {
      hash0[i] = hash[i];
    }
  }

  void _fillSegment(int pass, int slice, int lane) {
    int refLane, refIndex;
    int previous, current;
    int i, startIndex, random;

    bool xor = ctx.version != Argon2Version.v10 && pass > 0;
    bool useAddress = ctx.type == Argon2Type.argon2id
        ? pass == 0 && slice < ctx.midSlice
        : ctx.type != Argon2Type.argon2d;

    if (useAddress) {
      _input[0] = pass;
      _input[1] = lane;
      _input[2] = slice;
      _input[3] = ctx.blocks;
      _input[4] = ctx.passes;
      _input[5] = ctx.type.value;
      _input[6] = 0;
    }

    startIndex = 0;
    if (pass == 0 && slice == 0) {
      startIndex = 2;
      if (useAddress) {
        _input[6]++;
        _nextAddress(_input, _address);
      }
    }

    current = lane * ctx.columns + slice * ctx.segments + startIndex;

    for (i = startIndex; i < ctx.segments; ++i, ++current) {
      if (current % ctx.columns == 0) {
        previous = current + ctx.columns - 1;
      } else {
        previous = current - 1;
      }

      if (useAddress) {
        if ((i & 0x7F) == 0) {
          _input[6]++;
          _nextAddress(_input, _address);
        }
        random = _address[i & 0x7F];
      } else {
        random = _memory[previous << 7];
      }

      refLane = (random >>> 32) % ctx.lanes;
      if (pass == 0 && slice == 0) {
        refLane = lane;
      }

      refIndex = _alphaIndex(
        pass: pass,
        slice: slice,
        lane: lane,
        index: i,
        random: random & _mask32,
        sameLane: refLane == lane,
      );

      _fillBlock(
        _memory,
        xor: xor,
        next: current << 7,
        prev: previous << 7,
        ref: (refLane * ctx.columns + refIndex) << 7,
      );
    }
  }

  int _alphaIndex({
    required int pass,
    required int slice,
    required int lane,
    required int index,
    required int random,
    required bool sameLane,
  }) {
    int area, pos, start;

    if (pass == 0) {
      if (slice == 0) {
        area = index - 1;
      } else if (sameLane) {
        area = slice * ctx.segments + index - 1;
      } else if (index == 0) {
        area = slice * ctx.segments - 1;
      } else {
        area = slice * ctx.segments;
      }
    } else {
      if (sameLane) {
        area = ctx.columns - ctx.segments + index - 1;
      } else if (index == 0) {
        area = ctx.columns - ctx.segments - 1;
      } else {
        area = ctx.columns - ctx.segments;
      }
    }

    pos = (random * random) >>> 32;
    pos = area - 1 - ((area * pos) >>> 32);

    start = 0;
    if (pass != 0 && slice != ctx.slices - 1) {
      start = (slice + 1) * ctx.segments;
    }

    return (start + pos) % ctx.columns;
  }

  void _nextAddress(Uint64List input, Uint64List address) {
    for (int i = 0; i < 128; ++i) {
      _blockR[i] = address[i] = input[i];
    }

    for (int k = 0; k < 2; ++k) {
      _applyBlake2bRounds(_blockR);
      for (int i = 0; i < 128; ++i) {
        address[i] = _blockR[i] ^= address[i];
      }
    }
  }

  void _fillBlock(
    Uint64List memory, {
    required int prev,
    required int ref,
    required int next,
    bool xor = false,
  }) {
    for (int i = 0; i < 128; ++i) {
      _blockT[i] = _blockR[i] = memory[ref + i] ^ memory[prev + i];
    }

    if (xor) {
      for (int i = 0; i < 128; ++i) {
        _blockT[i] ^= memory[next + i];
      }
    }

    _applyBlake2bRounds(_blockR);

    for (int i = 0; i < 128; ++i) {
      memory[next + i] = _blockR[i] ^ _blockT[i];
    }
  }
}
