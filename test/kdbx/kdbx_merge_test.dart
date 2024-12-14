import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../test_resources.dart';
import 'test_database.dart';
import 'test_entry.dart';
import 'test_group.dart';
import 'test_times.dart';

abstract class DT {
  static final pre1 = DateTime.utc(2014, 1, 1);
  static final created = DateTime.utc(2015, 1, 1);
  static final upd1 = DateTime.utc(2015, 1, 2);
  static final upd2 = DateTime.utc(2015, 1, 3);
  static final upd3 = DateTime.utc(2015, 1, 4);
  static final upd4 = DateTime.utc(2015, 1, 5);
  static final upd5 = DateTime.utc(2015, 1, 6);
  static final upd6 = DateTime.utc(2015, 1, 7);
}

abstract class ID {
  static final trash = KdbxUuid.fromString('9YzmMdHbemuDYKZ2SXZ4rA==');
  static final tpl = KdbxUuid.fromString('HcvHxsuqUvKEXDzR5u3uYg==');
  static final eDel = KdbxUuid.fromString('8UHyJlaQJxJJZ36JsJmRAA==');
  static final eDel1 = KdbxUuid.random();
  static final icon1 = KdbxUuid.fromString('KqftU5TZ6Gm5+8u8XYmb6w==');
  static final icon2 = KdbxUuid.fromString('itP6FcgcT7W0C/dHw5Z3IQ==');
  static final bin1 = KdbxUuid.random();
  static final bin2 = KdbxUuid.random();
  static final bin3 = KdbxUuid.random();
  static final bin4 = KdbxUuid.random();
  static final gRoot = KdbxUuid.fromString('TjRl6BcM0edw1AHQ3XH1zQ==');
  static final g1 = KdbxUuid.fromString('ah263ZqkMgRIcP/27r+BlA==');
  static final g11 = KdbxUuid.fromString('ADLV65wPRSfVl/l8O9LIHA==');
  static final g111 = KdbxUuid.fromString('sI3L7jDwR8EmolhS5NGv9g==');
  static final g112 = KdbxUuid.fromString('5O9Dsq+MQsdaUL/HrfNHSw==');
  static final g12 = KdbxUuid.fromString('rgHq9KaNYAs7hb/ipe/hsw==');
  static final g2 = KdbxUuid.fromString('GTuz0U98L5pWOmxyq+AVOA==');
  static final g3 = KdbxUuid.fromString('EVnfZW6jPxecu2rqSaNjOw==');
  static final g31 = KdbxUuid.fromString('j2RvJyz0cKoaFKMP1imRPQ==');
  static final g4 = KdbxUuid.random();
  static final g5 = KdbxUuid.random();
  static final er1 = KdbxUuid.fromString('Gaw1wicctuAGKCI7t2udLw==');
}

abstract class Bin {
  static final bin1 = utf8.encode('bin1');
  static final bin2 = utf8.encode('bin2');
  static final bin3 = utf8.encode('bin3');
  static final bin4 = utf8.encode('bin4');
  static final icon1 = utf8.encode('icon1');
  static final icon2 = utf8.encode('icon2');
}

KdbxDatabase _getDb() => KdbxDatabase.fromBytes(
    data: TestResources.mergeKdbx,
    credentials: KdbxCredentials(password: ProtectedData.fromString('demo')));

TestDatabase _getTestDb() {
  final binaries = KdbxBinaries()
    ..add(PlainBinary(data: Bin.bin1, compressed: false));
  final customData = KdbxCustomData()
    ..map = {'cd1': KdbxCustomItem(value: 'data1')};

  return TestDatabase(
      meta: TestMeta(
          name: 'name',
          nameChanged: DT.created,
          description: 'desc',
          descriptionChanged: DT.created,
          defaultUser: 'user',
          defaultUserChanged: DT.created,
          maintenanceHistoryDays: 10,
          keyChanged: DT.created,
          keyChangeRec: 100,
          keyChangeForce: 200,
          recycleBinEnabled: true,
          recycleBinUuid: ID.trash,
          recycleBinChanged: DT.created,
          entryTemplatesGroup: ID.tpl,
          entryTemplatesGroupChanged: DT.created,
          historyMaxItems: 10,
          historyMaxSize: 10000,
          customIcons: {
            ID.icon1: KdbxCustomIcon(data: Bin.icon1),
            ID.icon2: KdbxCustomIcon(data: Bin.icon2),
          },
          customData: customData,
          settingsChanged: DT.created),
      binaries: binaries,
      deletedObjects: {ID.eDel: DT.upd1},
      root: TestGroup(
          uuid: ID.gRoot,
          name: 'root',
          notes: 'notes',
          icon: 1,
          customIcon: ID.icon1,
          times: TestTimes(modification: DT.upd1),
          isExpanded: false,
          groups: [
            TestGroup(uuid: ID.trash, name: 'trash'),
            TestGroup(
              uuid: ID.g1,
              name: 'g1',
              groups: [
                TestGroup(uuid: ID.g11, name: 'g11', groups: [
                  TestGroup(uuid: ID.g111, name: 'g111'),
                  TestGroup(uuid: ID.g112, name: 'g112')
                ]),
                TestGroup(uuid: ID.g12, name: 'g12')
              ],
            ),
            TestGroup(uuid: ID.g2, name: 'g2'),
            TestGroup(
              uuid: ID.g3,
              name: 'g3',
              groups: [TestGroup(uuid: ID.g31, name: 'g31')],
            )
          ],
          entries: [
            TestEntry(
                uuid: ID.er1,
                icon: 2,
                customIcon: ID.icon2.string,
                fgColor: '#ff0000',
                bgColor: '#00ff00',
                overrideUrl: '123',
                tags: ['tags'],
                times: TestTimes(modification: DT.upd3),
                fields: {'Title': 'er1', 'Password': 'pass'},
                binaries: {'bin1': binaries.all.first.hash},
                history: [
                  TestEntry(
                      uuid: ID.er1,
                      times: TestTimes(modification: DT.upd1),
                      tags: ['tags1']),
                  TestEntry(
                      uuid: ID.er1,
                      times: TestTimes(modification: DT.upd2),
                      tags: ['tags2'])
                ])
          ],
          defaultAutoTypeSeq: 'seq',
          enableAutoType: true,
          enableSearching: true));
}

void main() {
  group('Database merge unit tests', () {
    setUp(() async {
      await TestResources.init();
    });

    test('checks database structure', () {
      expect(_getTestDb().isEqual(_getDb()), true);
    });

    test('merges itself', () {
      final db = _getDb(), remote = _getDb();
      db.merge(remote);
      expect(_getTestDb().isEqual(db), true);
    });

    test('generates merge error when merging db without root', () {
      final db = _getDb();
      final remote = KdbxDatabase.create(
          name: 'demo',
          credentials:
              KdbxCredentials(password: ProtectedData.fromString('demo')));
      remote.groups.clear();
      expect(
          () => db.merge(remote),
          throwsA(predicate((e) =>
              e is InvalidStateError && e.message.contains('no root group'))));
    });

    test('generates merge error when merging another db', () {
      final db = _getDb();
      final remote = KdbxDatabase.create(
          name: 'demo',
          credentials:
              KdbxCredentials(password: ProtectedData.fromString('demo')));

      expect(
          () => db.merge(remote),
          throwsA(predicate((e) =>
              e is MergeError &&
              e.message.contains('root group is different'))));
    });

    test('merges deleted objects', () {
      final db = _getDb();
      final remote = _getDb();
      remote.deletedObjects[ID.eDel1] = KdbxTime(DT.upd2);
      db.merge(remote);
      expect(
          MapEquality().equals(
              db.deletedObjects.map((k, v) => MapEntry(k, v.time)),
              {ID.eDel: DT.upd1, ID.eDel1: DT.upd2}),
          true);
    });

    test('merges metadata when remote is later', () {
      final db = _getDb();
      final remote = _getDb();
      remote.meta.name = 'name1';
      remote.meta.nameChanged = KdbxTime(DT.upd2);
      remote.meta.description = 'desc1';
      remote.meta.descriptionChanged = KdbxTime(DT.upd2);
      remote.meta.defaultUser = 'user1';
      remote.meta.defaultUserChanged = KdbxTime(DT.upd2);
      remote.meta.maintenanceHistoryDays = 100;
      remote.meta.settingsChanged = KdbxTime(DT.upd2);
      remote.meta.keyChanged = KdbxTime(DT.upd2);
      remote.meta.keyChangeRec = 1000;
      remote.meta.keyChangeForce = 2000;
      remote.meta.recycleBinEnabled = false;
      remote.meta.recycleBinUuid = ID.g1;
      remote.meta.recycleBinChanged = KdbxTime(DT.upd2);
      remote.meta.entryTemplatesGroup = ID.g2;
      remote.meta.entryTemplatesGroupChanged = KdbxTime(DT.upd2);
      remote.meta.historyMaxItems = 100;
      remote.meta.historyMaxSize = 100000000;
      remote.meta.color = '#ff0000';
      db.merge(remote);

      final testMeta = TestMeta(
          name: 'name1',
          nameChanged: DT.upd2,
          description: 'desc1',
          descriptionChanged: DT.upd2,
          defaultUser: 'user1',
          defaultUserChanged: DT.upd2,
          maintenanceHistoryDays: 100,
          settingsChanged: DT.upd2,
          keyChanged: DT.upd2,
          keyChangeRec: 1000,
          keyChangeForce: 2000,
          recycleBinEnabled: false,
          recycleBinUuid: ID.g1,
          recycleBinChanged: DT.upd2,
          entryTemplatesGroup: ID.g2,
          entryTemplatesGroupChanged: DT.upd2,
          historyMaxItems: 100,
          historyMaxSize: 100000000,
          color: '#ff0000',
          customIcons: {
            ID.icon1: KdbxCustomIcon(data: Bin.icon1),
            ID.icon2: KdbxCustomIcon(data: Bin.icon2),
          },
          customData: KdbxCustomData()
            ..map = {'cd1': KdbxCustomItem(value: 'data1')});

      expect(testMeta.isEqual(db.meta), true);
    });

    test('merges metadata when local is later', () {
      final db = _getDb();
      final remote = _getDb();
      db.meta.name = 'name1';
      db.meta.nameChanged = KdbxTime(DT.upd2);
      db.meta.description = 'desc1';
      db.meta.descriptionChanged = KdbxTime(DT.upd2);
      db.meta.defaultUser = 'user1';
      db.meta.defaultUserChanged = KdbxTime(DT.upd2);
      db.meta.maintenanceHistoryDays = 100;
      db.meta.keyChanged = KdbxTime(DT.upd2);
      db.meta.keyChangeRec = 1000;
      db.meta.keyChangeForce = 2000;
      db.meta.recycleBinEnabled = false;
      db.meta.recycleBinUuid = ID.g1;
      db.meta.recycleBinChanged = KdbxTime(DT.upd2);
      db.meta.entryTemplatesGroup = ID.g2;
      db.meta.entryTemplatesGroupChanged = KdbxTime(DT.upd2);
      db.meta.historyMaxItems = 100;
      db.meta.historyMaxSize = 100000000;
      db.meta.color = '#ff0000';
      db.merge(remote);

      final testMeta = TestMeta(
          name: 'name1',
          nameChanged: DT.upd2,
          description: 'desc1',
          descriptionChanged: DT.upd2,
          defaultUser: 'user1',
          defaultUserChanged: DT.upd2,
          maintenanceHistoryDays: 100,
          settingsChanged: DT.created,
          keyChanged: DT.upd2,
          keyChangeRec: 1000,
          keyChangeForce: 2000,
          recycleBinEnabled: false,
          recycleBinUuid: ID.g1,
          recycleBinChanged: DT.upd2,
          entryTemplatesGroup: ID.g2,
          entryTemplatesGroupChanged: DT.upd2,
          historyMaxItems: 100,
          historyMaxSize: 100000000,
          color: '#ff0000',
          customIcons: {
            ID.icon1: KdbxCustomIcon(data: Bin.icon1),
            ID.icon2: KdbxCustomIcon(data: Bin.icon2),
          },
          customData: KdbxCustomData()
            ..map = {'cd1': KdbxCustomItem(value: 'data1')});

      expect(testMeta.isEqual(db.meta), true);
    });

    test('merges binaries', () {
      final db = _getDb();
      final remote = _getDb();

      final bin1 = PlainBinary(data: Bin.bin1, compressed: false);
      final bin2 = PlainBinary(data: Bin.bin2, compressed: false);
      final bin3 = PlainBinary(data: Bin.bin3, compressed: false);

      final testDb = _getTestDb();
      testDb.binaries.add(bin1);
      final ref2 = testDb.binaries.add(bin2);
      final ref3 = testDb.binaries.add(bin3);
      testDb.root.entries.first.binaries?['bin2'] = bin2.hash;

      db.root.entries.first.binaries['bin2'] = ref2;
      db.root.entries.first.history.first.binaries['bin2'] = ref3;
      db.binaries.add(bin2);

      remote.binaries.add(bin3);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('merges custom icons', () {
      final db = _getDb();
      final remote = _getDb();

      final d1 = DateTime.now();
      final d2 = d1.add(Duration(seconds: 1));

      final testMeta = _getTestDb().meta;
      testMeta.customIcons = {
        ID.icon2: KdbxCustomIcon(data: Bin.icon2),
        ID.bin1: KdbxCustomIcon(data: Bin.bin1),
        ID.bin3:
            KdbxCustomIcon(data: Bin.bin3, name: 'i3', modified: KdbxTime(d1)),
        ID.bin4:
            KdbxCustomIcon(data: Bin.bin4, name: 'i4', modified: KdbxTime(d2)),
        ID.bin2: KdbxCustomIcon(data: Bin.bin2)
      };

      db.meta.customIcons.addAll({
        ID.bin1: KdbxCustomIcon(data: Bin.bin1),
        ID.bin3:
            KdbxCustomIcon(data: Bin.bin3, name: 'i3', modified: KdbxTime(d1)),
        ID.bin4:
            KdbxCustomIcon(data: Bin.bin4, name: 'i4', modified: KdbxTime(d1))
      });
      db.root.customIcon = ID.bin1;
      db.root.times.touch();
      db.root.groups[0].customIcon = ID.bin3;
      db.root.groups[0].times.touch();
      db.root.groups[1].customIcon = ID.bin4;
      db.root.groups[1].times.touch();
      db.root.groups[1].customIcon = ID.bin4;
      db.root.groups[1].times.touch();

      remote.meta.customIcons.addAll({
        ID.bin2: KdbxCustomIcon(data: Bin.bin2),
        ID.bin4:
            KdbxCustomIcon(data: Bin.bin4, name: 'i4', modified: KdbxTime(d2))
      });
      remote.root.entries[0].customIcon = ID.bin2;
      remote.root.entries[0].times.touch();

      db.merge(remote);
      expect(testMeta.isEqual(db.meta), true);
    });

    test('merges custom data', () {
      final db = _getDb();
      final remote = _getDb();

      final d1 = KdbxTime.now();
      final d2 = KdbxTime(d1.time!.add(Duration(seconds: 1)));

      final testMeta = _getTestDb().meta;
      testMeta.customData.map = {
        'cd1': KdbxCustomItem(value: 'data1'),
        'dLocal': KdbxCustomItem(value: 'local'),
        '1': KdbxCustomItem(value: 'remoteNew', modification: d2),
        '2': KdbxCustomItem(value: 'new', modification: d2),
        'dRemote': KdbxCustomItem(value: 'remote')
      };

      db.meta.customData.map['dLocal'] = KdbxCustomItem(value: 'local');
      db.meta.customData.map['1'] =
          KdbxCustomItem(value: 'old', modification: d1);
      db.meta.customData.map['2'] =
          KdbxCustomItem(value: 'new', modification: d2);

      remote.meta.customData.map['dRemote'] = KdbxCustomItem(value: 'remote');
      remote.meta.customData.map['1'] =
          KdbxCustomItem(value: 'remoteNew', modification: d2);
      remote.meta.customData.map['2'] =
          KdbxCustomItem(value: 'remoteOld', modification: d1);

      db.merge(remote);
      expect(testMeta.isEqual(db.meta), true);
    });

    test('changes remote group', () {
      final db = _getDb();
      final remote = _getDb();

      final grp = remote.root;
      grp.name = 'root1';
      grp.notes = 'notes1';
      grp.icon = KdbxIcon.fromInt(1);
      grp.customIcon = ID.icon2;
      grp.times.modification = KdbxTime(DT.upd2);
      grp.isExpanded = true;
      grp.defaultAutoTypeSeq = 'seq1';
      grp.isAutoTypeEnabled = false;
      grp.isSearchingEnabled = false;
      grp.lastTopVisibleEntry = ID.eDel1;
      grp.groups[1].customIcon = ID.icon1;
      grp.groups[1].times.modification = KdbxTime(DT.upd2);

      final testDb = _getTestDb();
      testDb.root.name = 'root1';
      testDb.root.notes = 'notes1';
      testDb.root.icon = 1;
      testDb.root.customIcon = ID.icon2;
      testDb.root.times!.modification = DT.upd2;
      testDb.root.isExpanded = true;
      testDb.root.defaultAutoTypeSeq = 'seq1';
      testDb.root.enableAutoType = false;
      testDb.root.enableSearching = false;
      testDb.root.lastTopVisibleEntry = ID.eDel1;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds new remote group to root', () {
      final db = _getDb();
      final remote = _getDb();

      final group = remote.createGroup(parent: remote.root, name: 'newgrp');

      final testDb = _getTestDb();
      testDb.root.groups.add(TestGroup(
        uuid: group.uuid,
        name: group.name,
      ));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds new remote group to deep group', () {
      final db = _getDb();
      final remote = _getDb();

      final group = remote.createGroup(
          parent: remote.root.groups[1].groups[0], name: 'newgrp');

      final testDb = _getTestDb();
      testDb.root.groups[1].groups[0].groups.add(TestGroup(
        uuid: group.uuid,
        name: group.name,
      ));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes remote group', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToRemove = remote.root.groups[1].groups[0];
      remote.move(item: groupToRemove);

      final testDb = _getTestDb();
      testDb.root.groups[1].groups.removeAt(0);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves remote group to root', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToMove = remote.root.groups[1].groups[0];
      remote.move(item: groupToMove, target: remote.root);

      final testDb = _getTestDb();
      final g = testDb.root.groups[1].groups[0];
      testDb.root.groups.add(g);
      testDb.root.groups[1].groups.remove(g);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves remote group to deep group', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToMove = remote.root.groups[1].groups[0];
      remote.move(item: groupToMove, target: remote.root.groups[3]);

      final testDb = _getTestDb();
      final g = testDb.root.groups[1].groups[0];
      testDb.root.groups[3].groups.add(g);
      testDb.root.groups[1].groups.remove(g);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('changes local group', () {
      final db = _getDb();
      final remote = _getDb();

      final grp = db.root;
      grp.name = 'root1';
      grp.notes = 'notes1';
      grp.icon = KdbxIcon.fromInt(1);
      grp.customIcon = ID.icon2;
      grp.times.modification = KdbxTime(DT.upd2);
      grp.isExpanded = true;
      grp.defaultAutoTypeSeq = 'seq1';
      grp.isAutoTypeEnabled = false;
      grp.isSearchingEnabled = false;
      grp.lastTopVisibleEntry = ID.eDel1;
      grp.groups[1].customIcon = ID.icon1;
      grp.groups[1].times.modification = KdbxTime(DT.upd2);

      final testDb = _getTestDb();
      testDb.root.name = 'root1';
      testDb.root.notes = 'notes1';
      testDb.root.icon = 1;
      testDb.root.customIcon = ID.icon2;
      testDb.root.times!.modification = DT.upd2;
      testDb.root.isExpanded = true;
      testDb.root.defaultAutoTypeSeq = 'seq1';
      testDb.root.enableAutoType = false;
      testDb.root.enableSearching = false;
      testDb.root.lastTopVisibleEntry = ID.eDel1;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds new local group to root', () {
      final db = _getDb();
      final remote = _getDb();

      final group = db.createGroup(parent: remote.root, name: 'newgrp');

      final testDb = _getTestDb();
      testDb.root.groups.add(TestGroup(uuid: group.uuid, name: group.name));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds new local group to deep group', () {
      final db = _getDb();
      final remote = _getDb();

      final group = db.createGroup(
        parent: db.root.groups[1].groups[0],
        name: 'newgrp',
      );

      final testDb = _getTestDb();
      testDb.root.groups[1].groups[0].groups
          .add(TestGroup(uuid: group.uuid, name: group.name));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes local group', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToRemove = db.root.groups[1].groups[0];
      db.move(item: groupToRemove);

      final testDb = _getTestDb();
      testDb.root.groups[1].groups.removeAt(0);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves local group to root', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToMove = db.root.groups[1].groups[0];
      db.move(item: groupToMove, target: db.root);

      final testDb = _getTestDb();
      final g = testDb.root.groups[1].groups[0];
      testDb.root.groups.add(g);
      testDb.root.groups[1].groups.remove(g);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves local group to deep group', () {
      final db = _getDb();
      final remote = _getDb();

      final groupToMove = db.root.groups[1].groups[0];
      db.move(item: groupToMove, target: db.root.groups[3]);

      final testDb = _getTestDb();
      final g = testDb.root.groups[1].groups[0];
      testDb.root.groups[3].groups.add(g);
      testDb.root.groups[1].groups.remove(g);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes group moved to subgroup of locally deleted group', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(
          item: remote.root.groups[1].groups[0],
          target: remote.root.groups[3].groups[0]);

      db.move(item: db.root.groups[3]);

      final testDb = _getTestDb();
      testDb.root.groups[1].groups.removeAt(0);
      testDb.root.groups.removeAt(3);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes group moved to subgroup of remotely deleted group', () {
      final db = _getDb();
      final remote = _getDb();

      db.move(
          item: db.root.groups[1].groups[0],
          target: db.root.groups[3].groups[0]);
      remote.move(item: remote.root.groups[3]);

      final testDb = _getTestDb();
      testDb.root.groups[1].groups.removeAt(0);
      testDb.root.groups.removeAt(3);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes group moved out of subgroup of locally deleted group', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(
          item: remote.root.groups[1].groups[0],
          target: remote.root.groups[3].groups[0]);

      db.move(item: db.root.groups[1]);

      final testDb = _getTestDb();
      testDb.root.groups.removeAt(1);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes group moved out of subgroup of remotely deleted group', () {
      final db = _getDb();
      final remote = _getDb();

      db.move(
          item: db.root.groups[1].groups[0],
          target: db.root.groups[3].groups[0]);

      remote.move(item: remote.root.groups[1]);

      final testDb = _getTestDb();
      testDb.root.groups.removeAt(1);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves group moved to locally moved group', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(
          item: remote.root.groups[1].groups[0],
          target: remote.root.groups[3].groups[0]);

      db.move(item: db.root.groups[3], target: db.root.groups[2]);

      final testDb = _getTestDb();
      testDb.root.groups[3].groups[0].groups
          .add(testDb.root.groups[1].groups[0]);
      testDb.root.groups[1].groups.removeAt(0);
      testDb.root.groups[2].groups.add(testDb.root.groups[3]);
      testDb.root.groups.removeAt(3);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves group moved to remotely moved group', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(item: remote.root.groups[3], target: remote.root.groups[2]);

      db.move(
          item: db.root.groups[1].groups[0],
          target: db.root.groups[3].groups[0]);

      final testDb = _getTestDb();
      testDb.root.groups[3].groups[0].groups
          .add(testDb.root.groups[1].groups[0]);
      testDb.root.groups[1].groups.removeAt(0);
      testDb.root.groups[2].groups.add(testDb.root.groups[3]);
      testDb.root.groups.removeAt(3);
      testDb.deletedObjects = null;

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves group back', () {
      final db = _getDb();
      final remote = _getDb();

      var group4 = db.createGroup(parent: db.root, name: 'g4');
      group4.uuid = ID.g4;
      group4.times.modification = KdbxTime(DT.upd1);
      group4.times.locationChange = KdbxTime(DT.upd1);
      var group5 = db.createGroup(parent: db.root, name: 'g5');
      group5.uuid = ID.g5;
      group5.times.modification = KdbxTime(DT.upd1);
      group5.times.locationChange = KdbxTime(DT.upd1);

      db.root.groups.replaceRange(1, 3, [db.root.groups[2], db.root.groups[1]]);
      db.root.groups[1].times.modification = KdbxTime(DT.upd3);

      group5 = remote.createGroup(parent: remote.root, name: 'g5');
      group5.uuid = ID.g5;
      group5.times.modification = KdbxTime(DT.upd1);
      group5.times.locationChange = KdbxTime(DT.upd1);
      group4 = remote.createGroup(parent: remote.root, name: 'g4');
      group4.uuid = ID.g4;
      group4.times.modification = KdbxTime(DT.upd2);
      group4.times.locationChange = KdbxTime(DT.upd2);

      final testDb = _getTestDb();
      testDb.root.groups
          .replaceRange(1, 3, [testDb.root.groups[2], testDb.root.groups[1]]);
      testDb.root.groups[1].times = TestTimes(modification: DT.upd3);
      testDb.root.groups.addAll([
        TestGroup(uuid: ID.g5, name: 'g5'),
        TestGroup(uuid: ID.g4, name: 'g4')
      ]);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves group forward', () {
      final db = _getDb();
      final remote = _getDb();

      var group4 = db.createGroup(parent: db.root, name: 'g4');
      group4.uuid = ID.g4;
      group4.times.modification = KdbxTime(DT.upd1);
      group4.times.locationChange = KdbxTime(DT.upd1);
      var group5 = db.createGroup(parent: db.root, name: 'g5');
      group5.uuid = ID.g5;
      group5.times.modification = KdbxTime(DT.upd1);
      group5.times.locationChange = KdbxTime(DT.upd1);

      db.root.groups.replaceRange(1, 3, [db.root.groups[2], db.root.groups[1]]);
      db.root.groups[2].times.modification = KdbxTime(DT.upd3);

      group5 = remote.createGroup(parent: remote.root, name: 'g5');
      group5.uuid = ID.g5;
      group5.times.modification = KdbxTime(DT.upd1);
      group5.times.locationChange = KdbxTime(DT.upd1);
      group4 = remote.createGroup(parent: remote.root, name: 'g4');
      group4.uuid = ID.g4;
      group4.times.modification = KdbxTime(DT.upd2);
      group4.times.locationChange = KdbxTime(DT.upd2);

      final testDb = _getTestDb();
      testDb.root.groups
          .replaceRange(1, 3, [testDb.root.groups[2], testDb.root.groups[1]]);
      testDb.root.groups[2].times = TestTimes(modification: DT.upd3);
      testDb.root.groups.addAll([
        TestGroup(uuid: ID.g5, name: 'g5'),
        TestGroup(uuid: ID.g4, name: 'g4')
      ]);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('inserts group at start', () {
      final db = _getDb();
      final remote = _getDb();

      final group4 = remote.createGroup(
        parent: remote.root,
        name: 'g4',
      );
      group4.uuid = ID.g4;
      group4.times.modification = KdbxTime(DT.upd2);
      group4.times.locationChange = KdbxTime(DT.upd2);

      db.root.groups.removeLast();
      db.root.groups = [group4, ...db.root.groups];

      final testDb = _getTestDb();
      testDb.root.groups = [
        TestGroup(uuid: ID.g4, name: 'g4'),
        ...testDb.root.groups
      ];

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds remote entry', () {
      final db = _getDb();
      final remote = _getDb();

      final entry = remote.createEntry(parent: remote.root);
      entry.fields['added'] = KdbxTextField.fromText(text: 'field');

      final testDb = _getTestDb();
      testDb.root.entries.add(TestEntry(uuid: entry.uuid, fields: {
        'Notes': '',
        'Title': '',
        'URL': '',
        'UserName': 'user',
        'Password': '',
        'added': 'field'
      }));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes remote entry', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(item: remote.root.entries[0]);

      final testDb = _getTestDb();
      testDb.deletedObjects = null;
      testDb.meta.customIcons = null;
      testDb.root.entries.removeAt(0);
      testDb.binaries = KdbxBinaries();

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes local entry', () {
      final db = _getDb();
      final remote = _getDb();

      db.move(item: db.root.entries[0]);

      final testDb = _getTestDb();
      testDb.deletedObjects = null;
      testDb.meta.customIcons = null;
      testDb.root.entries.removeAt(0);
      testDb.binaries = KdbxBinaries();

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves remote entry', () {
      final db = _getDb();
      final remote = _getDb();

      remote.move(item: remote.root.entries[0], target: remote.root.groups[1]);

      final testDb = _getTestDb();
      testDb.deletedObjects = null;
      testDb.meta.customIcons = null;
      testDb.root.groups[1].entries.add(testDb.root.entries.first);
      testDb.root.entries.removeAt(0);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('moves local entry', () {
      final db = _getDb();
      final remote = _getDb();

      db.move(item: db.root.entries[0], target: db.root.groups[1]);

      final testDb = _getTestDb();
      testDb.deletedObjects = null;
      testDb.meta.customIcons = null;
      testDb.root.groups[1].entries.add(testDb.root.entries.first);
      testDb.root.entries.removeAt(0);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('changes remote entry', () {
      final db = _getDb();
      final remote = _getDb();

      final binary = <int>[];

      final entry = remote.root.entries.first;
      entry.icon = KdbxIcon.fromInt(21);
      entry.foreground = '#aa0000';
      entry.background = '#00aa00';
      entry.overrideUrl = '1234';
      entry.tags = ['tags1'];
      entry.times.modification = KdbxTime(DT.upd4);
      entry.fields = <String, KdbxTextField>{
        'Password': KdbxTextField.fromText(text: 'pass'),
        'Another': KdbxTextField.fromText(text: 'field'),
        'Protected': KdbxTextField.fromText(text: 'secret', protected: true)
      };

      final binaries = [
        PlainBinary(data: Bin.bin1, compressed: false),
        PlainBinary(data: Bin.bin2, compressed: false),
        PlainBinary(data: binary, compressed: false),
      ];

      final ref1 = remote.binaries.add(binaries[0]);
      final ref2 = remote.binaries.add(binaries[1]);
      final ref3 = remote.binaries.add(binaries[2]);

      entry.binaries.addAll({
        'bin1': ref1,
        'bin2': ref2,
        'ab': ref3,
      });

      final testDb = _getTestDb();
      testDb.binaries.add(binaries[0]);
      testDb.binaries.add(binaries[1]);
      testDb.binaries.add(binaries[2]);
      final e = testDb.root.entries.first;
      e.icon = 21;
      e.fgColor = '#aa0000';
      e.bgColor = '#00aa00';
      e.overrideUrl = '1234';
      e.tags = ['tags1'];
      e.times!.modification = DT.upd4;
      e.fields = {
        'Password': 'pass',
        'Another': 'field',
        'Protected': 'secret'
      };
      e.binaries!.addAll({
        'bin1': binaries[0].hash,
        'bin2': binaries[1].hash,
        'ab': binaries[2].hash,
      });
      e.history!.add(TestEntry(
          uuid: e.uuid,
          times: TestTimes(modification: DT.upd3),
          tags: ['tags']));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('ignores remote entry with same date', () {
      final db = _getDb();
      final remote = _getDb();

      final binary = <int>[];

      final entry = remote.root.entries.first;
      entry.icon = KdbxIcon.fromInt(21);
      entry.foreground = '#aa0000';
      entry.background = '#00aa00';
      entry.overrideUrl = '1234';
      entry.tags = ['tags1'];
      entry.fields = <String, KdbxTextField>{
        'Password': KdbxTextField.fromText(text: 'pass'),
        'Another': KdbxTextField.fromText(text: 'field'),
        'Protected': KdbxTextField.fromText(text: 'secret', protected: true)
      };

      final ref1 =
          db.binaries.add(PlainBinary(data: Bin.bin1, compressed: false));
      final ref2 =
          db.binaries.add(PlainBinary(data: Bin.bin2, compressed: false));
      final ref3 =
          db.binaries.add(PlainBinary(data: binary, compressed: false));

      entry.binaries.addAll({
        'bin1': ref1,
        'bin2': ref2,
        'ab': ref3,
      });

      final testDb = _getTestDb();

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('changes local entry', () {
      final db = _getDb();
      final remote = _getDb();

      final binary = <int>[];

      final entry = db.root.entries.first;
      entry.icon = KdbxIcon.fromInt(21);
      entry.foreground = '#aa0000';
      entry.background = '#00aa00';
      entry.overrideUrl = '1234';
      entry.tags = ['tags1'];
      entry.times.modification = KdbxTime(DT.upd4);
      entry.fields = <String, KdbxTextField>{
        'Password': KdbxTextField.fromText(text: 'pass'),
        'Another': KdbxTextField.fromText(text: 'field'),
        'Protected': KdbxTextField.fromText(text: 'secret', protected: true)
      };

      final binaries = [
        PlainBinary(data: Bin.bin1, compressed: false),
        PlainBinary(data: Bin.bin2, compressed: false),
        PlainBinary(data: binary, compressed: false),
      ];

      final ref1 = db.binaries.add(binaries[0]);
      final ref2 = db.binaries.add(binaries[1]);
      final ref3 = db.binaries.add(binaries[2]);

      entry.binaries.addAll({
        'bin1': ref1,
        'bin2': ref2,
        'ab': ref3,
      });

      final testDb = _getTestDb();
      testDb.binaries.add(binaries[0]);
      testDb.binaries.add(binaries[1]);
      testDb.binaries.add(binaries[2]);
      final e = testDb.root.entries.first;
      e.icon = 21;
      e.fgColor = '#aa0000';
      e.bgColor = '#00aa00';
      e.overrideUrl = '1234';
      e.tags = ['tags1'];
      e.times!.modification = DT.upd4;
      e.fields = {
        'Password': 'pass',
        'Another': 'field',
        'Protected': 'secret'
      };
      e.binaries!.addAll({
        'bin1': binaries[0].hash,
        'bin2': binaries[1].hash,
        'ab': binaries[2].hash,
      });
      e.history!.add(TestEntry(
          uuid: e.uuid,
          times: TestTimes(modification: DT.upd3),
          tags: ['tags']));

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes history state remotely', () {
      final db = _getDb();
      final remote = _getDb();

      remote.root.entries.first.removeFromHistory(start: 0);

      final testDb = _getTestDb();
      testDb.root.entries.first.history?.removeAt(0);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes history state locally', () {
      final db = _getDb();
      final remote = _getDb();

      db.root.entries.first.removeFromHistory(start: 0);

      final testDb = _getTestDb();
      testDb.root.entries.first.history?.removeAt(0);

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes all history states remotely', () {
      final db = _getDb();
      final remote = _getDb();

      remote.root.entries.first.removeFromHistory(start: 0, end: 2);

      final testDb = _getTestDb();
      testDb.root.entries.first.history?.clear();

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('deletes all history states locally', () {
      final db = _getDb();
      final remote = _getDb();

      db.root.entries.first.removeFromHistory(start: 0, end: 2);

      final testDb = _getTestDb();
      testDb.root.entries.first.history?.clear();

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds past history state remotely', () {
      final db = _getDb();
      final remote = _getDb();

      final remoteEntry = remote.root.entries.first;
      final entry = db.root.entries.first;

      remoteEntry.times.modification = KdbxTime(DT.upd3);
      entry.times.modification = KdbxTime(DT.upd4);
      remoteEntry.pushHistory();
      remoteEntry.times.modification = KdbxTime(DT.upd4);

      final testDb = _getTestDb();
      testDb.root.entries.first.times!.modification = DT.upd4;
      testDb.root.entries.first.history!.add(
        TestEntry(
          uuid: entry.uuid,
          times: TestTimes(modification: DT.upd3),
          tags: ['tags'],
        ),
      );

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test(
        'adds future history state remotely and converts current state into history',
        () {
      final db = _getDb();
      final remote = _getDb();

      final remoteEntry = remote.root.entries.first;
      final entry = db.root.entries.first;

      remoteEntry.times.modification = KdbxTime(DT.upd4);
      remoteEntry.tags = ['t4'];
      remoteEntry.pushHistory();
      remoteEntry.times.modification = KdbxTime(DT.upd5);
      remoteEntry.tags = ['tRemote'];
      entry.tags = ['tLocal'];

      final testDb = _getTestDb();
      testDb.root.entries.first.times!.modification = DT.upd5;
      testDb.root.entries.first.tags = ['tRemote'];
      testDb.root.entries.first.history!.addAll(
        [
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd3),
            tags: ['tLocal'],
          ),
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd4),
            tags: ['t4'],
          )
        ],
      );

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('adds history state locally and converts remote state into history',
        () {
      final db = _getDb();
      final remote = _getDb();

      final remoteEntry = remote.root.entries.first;
      final entry = db.root.entries.first;

      remoteEntry.times.modification = KdbxTime(DT.upd5);
      remoteEntry.tags = ['tRemote'];
      entry.tags = ['t4'];
      entry.times.modification = KdbxTime(DT.upd4);
      entry.pushHistory();
      entry.tags = ['tLocal'];
      entry.times.modification = KdbxTime(DT.upd6);

      final testDb = _getTestDb();
      testDb.root.entries.first.times!.modification = DT.upd6;
      testDb.root.entries.first.tags = ['tLocal'];
      testDb.root.entries.first.history!.addAll(
        [
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd4),
            tags: ['t4'],
          ),
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd5),
            tags: ['tRemote'],
          ),
        ],
      );

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('can merge with old entry state without state deletions', () {
      final db = _getDb();
      final remote = _getDb();

      final entry = db.root.entries.first;
      entry.times.modification = KdbxTime(DT.upd4);
      entry.tags = ['t4'];
      entry.pushHistory();
      entry.tags = ['tLocal'];
      entry.times.modification = KdbxTime(DT.upd5);
      db.clearLocalEditState();

      final testDb = _getTestDb();
      testDb.root.entries.first.times!.modification = DT.upd5;
      testDb.root.entries.first.tags = ['tLocal'];
      testDb.root.entries.first.history!.addAll(
        [
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd3),
            tags: ['tags'],
          ),
          TestEntry(
            uuid: entry.uuid,
            times: TestTimes(modification: DT.upd4),
            tags: ['t4'],
          )
        ],
      );

      db.merge(remote);
      expect(testDb.isEqual(db), true);
    });

    test('saves and restores edit state', () {
      final db = _getDb();
      final remote = _getDb();

      db.root.entries.first.removeFromHistory(start: 0);
      db.meta.historyMaxItems = 500;
      db.clearLocalEditState();

      final testDb = _getTestDb();

      db.merge(remote);
      expect(testDb.isEqual(db), true);

      db.root.entries.first.removeFromHistory(start: 0);
      db.meta.historyMaxItems = 500;

      final xml = db.localEditState.toXml().toXmlString(pretty: true);

      db.clearLocalEditState();
      db.localEditState =
          KdbxEditState.fromXml(XmlDocument.parse(xml).firstChild!);
      db.merge(remote);

      testDb.meta.historyMaxItems = 500;
      testDb.root.entries[0].history!.removeAt(0);
      expect(testDb.isEqual(db), true);
    });
  });
}
