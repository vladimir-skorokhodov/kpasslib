import 'package:kpasslib/kpasslib.dart';

import 'test_entry.dart';
import 'test_times.dart';

/// Represents test group structure
class TestGroup {
  KdbxUuid uuid;
  String name;
  String? notes;
  int? icon;
  KdbxUuid? customIcon;
  TestTimes? times;
  bool? isExpanded;
  var groups = <TestGroup>[];
  var entries = <TestEntry>[];
  String? defaultAutoTypeSeq;
  bool? enableAutoType;
  bool? enableSearching;
  KdbxUuid? lastTopVisibleEntry;

  TestGroup(
      {required this.uuid,
      required this.name,
      this.notes,
      this.icon,
      this.isExpanded,
      List<TestGroup>? groups,
      List<TestEntry>? entries,
      this.lastTopVisibleEntry,
      this.times,
      this.defaultAutoTypeSeq,
      this.enableAutoType,
      this.enableSearching,
      this.customIcon}) {
    this.groups = groups ?? this.groups;
    this.entries = entries ?? this.entries;
  }

  bool isEqual(KdbxGroup group, KdbxDatabase db) {
    if (groups.length != group.groups.length) {
      return false;
    }

    for (final (i, g) in groups.indexed) {
      if (!g.isEqual(group.groups[i], db)) {
        return false;
      }
    }

    if (entries.length != group.entries.length) {
      return false;
    }

    for (final (i, e) in entries.indexed) {
      if (!e.isEqual(group.entries[i], db)) {
        return false;
      }
    }

    return uuid == group.uuid &&
        name == group.name &&
        (notes == null || notes == group.notes) &&
        (icon == null || icon == group.icon.value) &&
        (isExpanded == null || isExpanded == group.isExpanded) &&
        (defaultAutoTypeSeq == null ||
            defaultAutoTypeSeq == group.defaultAutoTypeSeq) &&
        (lastTopVisibleEntry == null ||
            lastTopVisibleEntry == group.lastTopVisibleEntry) &&
        (customIcon == null || customIcon == group.customIcon) &&
        (times?.isEqual(group.times) ?? true);
  }
}
