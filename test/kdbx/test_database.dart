import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';

import 'test_group.dart';

/// Represents test meta structure
class TestMeta {
  String name;
  DateTime nameChanged;
  String description;
  DateTime descriptionChanged;
  String defaultUser;
  DateTime defaultUserChanged;
  int maintenanceHistoryDays;
  DateTime keyChanged;
  int keyChangeRec;
  int keyChangeForce;
  bool recycleBinEnabled;
  KdbxUuid recycleBinUuid;
  DateTime recycleBinChanged;
  KdbxUuid entryTemplatesGroup;
  DateTime entryTemplatesGroupChanged;
  int historyMaxItems;
  int historyMaxSize;
  Map<KdbxUuid, KdbxCustomIcon>? customIcons;
  KdbxCustomData customData;
  DateTime? settingsChanged;
  String? color;
  KdbxUuid? lastSelectedGroup;
  KdbxUuid? lastTopVisibleGroup;
  KdbxMemoryProtection? memoryProtection;

  TestMeta(
      {required this.name,
      required this.nameChanged,
      required this.description,
      required this.descriptionChanged,
      required this.defaultUser,
      required this.defaultUserChanged,
      required this.maintenanceHistoryDays,
      required this.keyChanged,
      required this.keyChangeRec,
      required this.keyChangeForce,
      required this.recycleBinEnabled,
      required this.recycleBinUuid,
      required this.recycleBinChanged,
      required this.entryTemplatesGroup,
      required this.entryTemplatesGroupChanged,
      required this.historyMaxItems,
      required this.historyMaxSize,
      required this.customIcons,
      required this.customData,
      this.lastSelectedGroup,
      this.lastTopVisibleGroup,
      this.memoryProtection,
      this.color,
      this.settingsChanged});

  bool isEqual(KdbxMeta meta) {
    final ci = customIcons;

    if (ci != null) {
      if (ci.length != meta.customIcons.length) {
        return false;
      }

      final mci = meta.customIcons.entries.toList();

      for (final (i, ci) in ci.entries.indexed) {
        if (ci.key != mci[i].key ||
            ci.value.name != mci[i].value.name ||
            ci.value.modified != mci[i].value.modified ||
            !ListEquality().equals(ci.value.data, mci[i].value.data)) {
          return false;
        }
      }
    }

    return name == meta.name &&
        nameChanged.isAtSameMomentAs(meta.nameChanged.timeOrZero) &&
        description == meta.description &&
        descriptionChanged
            .isAtSameMomentAs(meta.descriptionChanged.timeOrZero) &&
        defaultUser == meta.defaultUser &&
        defaultUserChanged
            .isAtSameMomentAs(meta.defaultUserChanged.timeOrZero) &&
        maintenanceHistoryDays == meta.maintenanceHistoryDays &&
        keyChanged.isAtSameMomentAs(meta.keyChanged.timeOrZero) &&
        keyChangeRec == meta.keyChangeRec &&
        keyChangeForce == meta.keyChangeForce &&
        recycleBinEnabled == meta.recycleBinEnabled &&
        recycleBinUuid == meta.recycleBinUuid &&
        recycleBinChanged.isAtSameMomentAs(meta.recycleBinChanged.timeOrZero) &&
        entryTemplatesGroup == meta.entryTemplatesGroup &&
        entryTemplatesGroupChanged
            .isAtSameMomentAs(meta.entryTemplatesGroupChanged.timeOrZero) &&
        historyMaxItems == meta.historyMaxItems &&
        historyMaxSize == meta.historyMaxSize &&
        (lastSelectedGroup == null ||
            lastSelectedGroup == meta.lastSelectedGroup) &&
        (lastTopVisibleGroup == null ||
            lastTopVisibleGroup == meta.lastTopVisibleGroup) &&
        (memoryProtection == null ||
            memoryProtection == meta.memoryProtection) &&
        color == meta.color &&
        (settingsChanged == null ||
            settingsChanged!
                .isAtSameMomentAs(meta.settingsChanged.timeOrZero)) &&
        MapEquality().equals(customData.map, meta.customData.map);
  }
}

/// Represents test database structure
class TestDatabase {
  TestMeta meta;
  KdbxBinaries binaries;
  Map<KdbxUuid, DateTime?>? deletedObjects;
  TestGroup root;

  TestDatabase(
      {required this.meta,
      required this.binaries,
      required this.deletedObjects,
      required this.root});

  bool isEqual(KdbxDatabase? db) {
    if (db == null) {
      return false;
    }

    final bins = binaries.all.map((binary) => binary.hash).toList();
    final dbBins = db.binaries.all.map((binary) => binary.hash).toList();

    return meta.isEqual(db.meta) &&
        ListEquality().equals(bins, dbBins) &&
        (deletedObjects == null ||
            MapEquality().equals(deletedObjects,
                db.deletedObjects.map((k, v) => MapEntry(k, v.time)))) &&
        root.isEqual(db.root, db);
  }
}
