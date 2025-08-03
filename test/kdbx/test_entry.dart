import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/kdbx/kdbx_autotype.dart';

import 'test_times.dart';

/// Represents test entry structure
class TestEntry {
  KdbxUuid uuid;
  int? icon;
  String? customIcon;
  String? fgColor;
  String? bgColor;
  String? overrideUrl;
  List<String>? tags;
  TestTimes? times;
  Map<String, String>? fields;
  Map<String, String>? binaries;
  KdbxAutoType? autoType;
  List<TestEntry>? history;

  TestEntry(
      {required this.uuid,
      this.icon,
      this.history,
      this.times,
      this.customIcon,
      this.fgColor,
      this.bgColor,
      this.overrideUrl,
      this.tags,
      this.fields,
      this.binaries,
      this.autoType});

  bool isEqual(KdbxEntry entry, KdbxDatabase db) {
    final f = fields;

    if (f != null) {
      if (f.length != entry.fields.length) {
        return false;
      }

      for (final e in f.entries) {
        final field = entry.fields[e.key];
        if (field is PlainTextField && e.value != field.text) {
          return false;
        }
        if (field is ProtectedTextField &&
            e.value != field.protectedText.text) {
          return false;
        }
      }
    }

    final b = binaries;

    if (b != null) {
      if (b.length != entry.binaries.length) {
        return false;
      }

      for (final e in b.entries) {
        final binary = entry.binaries[e.key];
        if (binary == null || e.value != db.binaries.getByRef(binary)?.hash) {
          return false;
        }
      }
    }

    final his = history;

    if (his != null) {
      if (his.length != entry.history.length) {
        return false;
      }

      for (final (i, h) in his.indexed) {
        if (!h.isEqual(entry.history[i], db)) {
          return false;
        }
      }
    }

    return uuid == entry.uuid &&
        (icon == null || icon == entry.icon.value) &&
        (customIcon == null || customIcon == entry.customIcon?.string) &&
        (fgColor == null || fgColor == entry.foreground) &&
        (bgColor == null || bgColor == entry.background) &&
        (overrideUrl == null || overrideUrl == entry.overrideUrl) &&
        (tags == null || ListEquality().equals(tags, entry.tags)) &&
        (times?.isEqual(entry.times) ?? true) &&
        (autoType == null || autoType == entry.autoType);
  }
}
