import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../aes.dart';

/// Dart AES-256 implementation using T-tables.
class Aes256Dart extends Aes256 {
  static const _nb = 4; // Block size in 32-bit words
  static const _nk = 8; // Key length in 32-bit words (256-bit)
  static const _nr = 14; // Number of rounds

  // S-box
  static const _sboxHex =
      '637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0'
      'b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b275'
      '09832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cf'
      'd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2'
      'cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdb'
      'e0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08'
      'ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9e'
      'e1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16';
  static final _sbox = Uint8List.fromList(hex.decode(_sboxHex));

  // Rcon
  static const _rcon = [
    0x00000000, 0x01000000, 0x02000000, 0x04000000, 0x08000000, //
    0x10000000, 0x20000000, 0x40000000, 0x80000000, 0x1b000000,
    0x36000000,
  ];

  // Inverse S-box
  static const _invSboxHex =
      '52096ad53036a538bf40a39e81f3d7fb7ce339829b2fff87348e4344c4dee9cb'
      '547b9432a6c2233dee4c950b42fac34e082ea16628d924b2765ba2496d8bd125'
      '72f8f66486689816d4a45ccc5d65b6926c704850fdedb9da5e154657a78d9d84'
      '90d8ab008cbcd30af7e45805b8b34506d02c1e8fca3f0f02c1afbd0301138a6b'
      '3a9111414f67dcea97f2cfcef0b4e67396ac7422e7ad3585e2f937e81c75df6e'
      '47f11a711d29c5896fb7620eaa18be1bfc563e4bc6d279209adbc0fe78cd5af4'
      '1fdda8338807c731b11210592780ec5f60517fa919b54a0d2de57a9f93c99cef'
      'a0e03b4dae2af5b0c8ebbb3c83539961172b047eba77d626e169146355210c7d';
  static final _invSbox = Uint8List.fromList(hex.decode(_invSboxHex));

  // T-tables (fused SubBytes + ShiftRows + MixColumns)
  static final _te0 = _makeTe((s, xt, x3) => xt << 24 | s << 16 | s << 8 | x3);
  static final _te1 = _makeTe((s, xt, x3) => x3 << 24 | xt << 16 | s << 8 | s);
  static final _te2 = _makeTe((s, xt, x3) => s << 24 | x3 << 16 | xt << 8 | s);
  static final _te3 = _makeTe((s, xt, x3) => s << 24 | s << 16 | x3 << 8 | xt);

  // Inverse T-tables (fused InvSubBytes + InvShiftRows + InvMixColumns)
  static final _td0 = _makeTd(0x0e, 0x09, 0x0d, 0x0b);
  static final _td1 = _makeTd(0x0b, 0x0e, 0x09, 0x0d);
  static final _td2 = _makeTd(0x0d, 0x0b, 0x0e, 0x09);
  static final _td3 = _makeTd(0x09, 0x0d, 0x0b, 0x0e);

  // Expanded key schedules
  final Uint32List _w;
  final Uint32List _dw;

  Aes256Dart._(this._w, this._dw);

  /// Creates a [Aes256Dart] cipher with the given 32-byte [key].
  factory Aes256Dart({required Uint8List key}) {
    if (key.length != 32) {
      throw ArgumentError('AES-256 requires a 32-byte key');
    }
    final kd = ByteData.sublistView(key);
    // KeyExpansion
    final w = Uint32List(_nb * (_nr + 1));
    for (var i = 0; i < _nk; i++) {
      w[i] = kd.getUint32(i * 4);
    }
    for (var i = _nk; i < w.length; i++) {
      var temp = w[i - 1];
      if (i % _nk == 0) {
        temp = _subWord(_rotWord(temp)) ^ _rcon[i ~/ _nk];
      } else if (i % _nk == 4) {
        temp = _subWord(temp);
      }
      w[i] = w[i - _nk] ^ temp;
    }
    return Aes256Dart._(w, _makeDecryptSchedule(w));
  }

  @override
  void transformBlock({required Uint8List data, required int rounds}) {
    final bd = ByteData.sublistView(data);
    for (var i = 0; i < rounds; i++) {
      _encryptBlock(bd);
    }
  }

  @override
  Uint8List encryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  }) {
    final padLen = padding ? 16 - (data.length % 16) : 0;
    final totalLen = data.length + padLen;
    final block = Uint8List(16)..setAll(0, iv);
    final bd = ByteData.sublistView(block);
    final output = Uint8List(totalLen);
    for (var offset = 0; offset < totalLen; offset += 16) {
      for (var i = 0; i < 16; i++) {
        final si = offset + i;
        block[i] ^= si < data.length ? data[si] : padLen;
      }
      _encryptBlock(bd);
      output.setRange(offset, offset + 16, block);
    }
    return output;
  }

  @override
  Uint8List decryptCbc({
    required Uint8List data,
    required Uint8List iv,
    bool padding = true,
  }) {
    final block = Uint8List(16);
    final bd = ByteData.sublistView(block);
    final prev = Uint8List(16)..setAll(0, iv);
    final output = Uint8List(data.length);
    for (var offset = 0; offset < data.length; offset += 16) {
      block.setRange(0, 16, data, offset);
      _decryptBlock(bd);
      for (var i = 0; i < 16; i++) {
        output[offset + i] = block[i] ^ prev[i];
        prev[i] = data[offset + i];
      }
    }
    if (!padding) return output;
    final padLen = output.last;
    return Uint8List.sublistView(output, 0, output.length - padLen);
  }

  void _encryptBlock(ByteData bd) {
    final w = _w;
    final te0 = _te0, te1 = _te1, te2 = _te2, te3 = _te3;
    var s0 = bd.getUint32(0) ^ w[0];
    var s1 = bd.getUint32(4) ^ w[1];
    var s2 = bd.getUint32(8) ^ w[2];
    var s3 = bd.getUint32(12) ^ w[3];
    for (var round = 1; round < _nr; round++) {
      final k = round * 4;
      final d0 = te0[s0 >> 24] ^
          te1[(s1 >> 16) & 0xff] ^
          te2[(s2 >> 8) & 0xff] ^
          te3[s3 & 0xff] ^
          w[k];
      final d1 = te0[s1 >> 24] ^
          te1[(s2 >> 16) & 0xff] ^
          te2[(s3 >> 8) & 0xff] ^
          te3[s0 & 0xff] ^
          w[k + 1];
      final d2 = te0[s2 >> 24] ^
          te1[(s3 >> 16) & 0xff] ^
          te2[(s0 >> 8) & 0xff] ^
          te3[s1 & 0xff] ^
          w[k + 2];
      final d3 = te0[s3 >> 24] ^
          te1[(s0 >> 16) & 0xff] ^
          te2[(s1 >> 8) & 0xff] ^
          te3[s2 & 0xff] ^
          w[k + 3];
      s0 = d0;
      s1 = d1;
      s2 = d2;
      s3 = d3;
    }
    final sbox = _sbox;
    final k = _nr * 4;
    bd.setUint32(0, _subBytes(sbox, s0, s1, s2, s3) ^ w[k]);
    bd.setUint32(4, _subBytes(sbox, s1, s2, s3, s0) ^ w[k + 1]);
    bd.setUint32(8, _subBytes(sbox, s2, s3, s0, s1) ^ w[k + 2]);
    bd.setUint32(12, _subBytes(sbox, s3, s0, s1, s2) ^ w[k + 3]);
  }

  void _decryptBlock(ByteData bd) {
    final w = _dw;
    final td0 = _td0, td1 = _td1, td2 = _td2, td3 = _td3;
    var s0 = bd.getUint32(0) ^ w[0];
    var s1 = bd.getUint32(4) ^ w[1];
    var s2 = bd.getUint32(8) ^ w[2];
    var s3 = bd.getUint32(12) ^ w[3];
    for (var round = 1; round < _nr; round++) {
      final k = round * 4;
      final d0 = td0[s0 >> 24] ^
          td1[(s3 >> 16) & 0xff] ^
          td2[(s2 >> 8) & 0xff] ^
          td3[s1 & 0xff] ^
          w[k];
      final d1 = td0[s1 >> 24] ^
          td1[(s0 >> 16) & 0xff] ^
          td2[(s3 >> 8) & 0xff] ^
          td3[s2 & 0xff] ^
          w[k + 1];
      final d2 = td0[s2 >> 24] ^
          td1[(s1 >> 16) & 0xff] ^
          td2[(s0 >> 8) & 0xff] ^
          td3[s3 & 0xff] ^
          w[k + 2];
      final d3 = td0[s3 >> 24] ^
          td1[(s2 >> 16) & 0xff] ^
          td2[(s1 >> 8) & 0xff] ^
          td3[s0 & 0xff] ^
          w[k + 3];
      s0 = d0;
      s1 = d1;
      s2 = d2;
      s3 = d3;
    }
    final isbox = _invSbox;
    final k = _nr * 4;
    bd.setUint32(0, _subBytes(isbox, s0, s3, s2, s1) ^ w[k]);
    bd.setUint32(4, _subBytes(isbox, s1, s0, s3, s2) ^ w[k + 1]);
    bd.setUint32(8, _subBytes(isbox, s2, s1, s0, s3) ^ w[k + 2]);
    bd.setUint32(12, _subBytes(isbox, s3, s2, s1, s0) ^ w[k + 3]);
  }

  static Uint32List _makeDecryptSchedule(Uint32List w) {
    final dw = Uint32List(_nb * (_nr + 1));
    for (var i = 0; i < 4; i++) {
      dw[i] = w[_nr * 4 + i];
      dw[_nr * 4 + i] = w[i];
    }
    for (var r = 1; r < _nr; r++) {
      for (var i = 0; i < 4; i++) {
        dw[r * 4 + i] = _invMixColumn(w[(_nr - r) * 4 + i]);
      }
    }
    return dw;
  }

  // Multiply by x (i.e. 2) in GF(2^8) with AES reduction polynomial
  static int _xtime(int a) => ((a << 1) ^ ((a >> 7) * 0x1b)) & 0xff;

  // Multiply two elements in GF(2^8) by repeated doubling
  static int _gmul(int a, int b) {
    var p = 0;
    for (var i = 0; i < 8; i++) {
      if (b & 1 != 0) p ^= a;
      a = _xtime(a);
      b >>= 1;
    }
    return p;
  }

  static Uint32List _makeTe(int Function(int s, int xt, int x3) pack) {
    final t = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      final s = _sbox[i];
      final xt = _xtime(s);
      t[i] = pack(s, xt, xt ^ s);
    }
    return t;
  }

  static Uint32List _makeTd(int a, int b, int c, int d) {
    final t = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      final s = _invSbox[i];
      t[i] = _gmul(s, a) << 24 |
          _gmul(s, b) << 16 |
          _gmul(s, c) << 8 |
          _gmul(s, d);
    }
    return t;
  }

  static int _subWord(int w) => _subBytes(_sbox, w, w, w, w);

  static int _rotWord(int w) => (w << 8) | ((w >> 24) & 0xff);

  static int _subBytes(Uint8List sbox, int c0, int c1, int c2, int c3) =>
      (sbox[(c0 >> 24) & 0xff] << 24) |
      (sbox[(c1 >> 16) & 0xff] << 16) |
      (sbox[(c2 >> 8) & 0xff] << 8) |
      sbox[c3 & 0xff];

  static int _invMixColumn(int col) {
    final s = _subWord(col);
    return _td0[s >> 24] ^
        _td1[(s >> 16) & 0xff] ^
        _td2[(s >> 8) & 0xff] ^
        _td3[s & 0xff];
  }
}
