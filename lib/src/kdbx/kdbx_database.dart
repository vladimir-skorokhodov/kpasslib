import 'dart:convert';
import 'dart:core';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../crypto/crypto_utils.dart';
import '../crypto/hashed_block_transform.dart';
import '../crypto/hmac_block_transform.dart';
import '../utils/byte_utils.dart';
import '../utils/merge_utils.dart';
import '../utils/xml_utils.dart';

/// An edit state of a [KdbxDatabase].
class KdbxEditState {
  /// The database entries edit state.
  var entries = <KdbxUuid, KdbxEntryEditState>{};

  /// The database meta edit state.
  var meta = KdbxMetaEditState.empty();

  /// Constructs an empty edit state.
  KdbxEditState.empty();

  /// Restores an edit state from an XML [node].
  factory KdbxEditState.fromXml(XmlNode node) {
    final state = KdbxEditState.empty();

    for (var e in node.childElements) {
      switch (e.qualifiedName) {
        case XmlElem.metaEditState:
          state.meta = KdbxMetaEditState.fromXml(e);
        case XmlElem.entry:
          state._readEntry(e);
      }
    }

    return state;
  }

  /// Serializes an the edit state to an XML node.
  XmlNode toXml() {
    return XmlUtils.createElement(name: XmlElem.kdbxEditState)
      ..children.addAll(
        [
          meta.toXml(),
          ...entries.entries.map(
            (entry) => XmlUtils.createElement(name: XmlElem.entry)
              ..children.addAll([
                XmlUtils.createElement(name: XmlElem.uuid)
                  ..innerText = entry.key.string,
                entry.value.toXml(),
              ]),
          ),
        ],
      );
  }

  _readEntry(XmlNode xmlNode) {
    KdbxUuid? id;
    KdbxEntryEditState? state;

    for (var e in xmlNode.childElements) {
      switch (e.qualifiedName) {
        case XmlElem.uuid:
          id = KdbxUuid.fromString(e.innerText,
              prohibited: entries.keys.toSet());
        case XmlElem.entryEditState:
          state = KdbxEntryEditState.fromXml(e);
      }
    }

    if (id != null && state != null) {
      entries[id] = state;
    }
  }
}

/// A KDBX database.
class KdbxDatabase {
  /// The KDBX database header structure.
  final KdbxHeader header;

  /// The KDBX database meta structure.
  final KdbxMeta meta;

  final _groups = <KdbxGroup>[];
  final _deletedObjects = <KdbxUuid, KdbxTime>{};

  KdbxDatabase._({required this.header, required this.meta});

  /// Creates a new database.
  factory KdbxDatabase.create({
    required KdbxCredentials credentials,
    required String name,
  }) {
    final db = KdbxDatabase._(
      header: KdbxHeader.create(credentials: credentials),
      meta: KdbxMeta.create(),
    );

    db._createRoot(name);
    db._createRecycleBin();

    final root = db.root.uuid;
    db.meta.lastSelectedGroup = root;
    db.meta.lastTopVisibleGroup = root;
    db.meta.name = name;

    return db;
  }

  /// Loads a [KdbxDatabase] from [data] with [credentials].
  static Future<KdbxDatabase> fromBytes({
    required List<int> data,
    required KdbxCredentials credentials,
  }) async {
    final reader = BytesReader(data);
    final header = KdbxHeader.fromBytes(
      credentials: credentials,
      reader: reader,
    );

    return switch (header.version.$1) {
      3 => _loadV3(reader: reader, header: header),
      4 => _loadV4(reader: reader, header: header),
      _ => throw UnsupportedValueError('bad version: ${header.version.$1}'),
    };
  }

  /// Imports a [KdbxDatabase] from [xmlString] with [credentials].
  factory KdbxDatabase.fromXmlString({
    required String xmlString,
    required KdbxCredentials credentials,
  }) {
    XmlDocument xml;

    try {
      xml = XmlDocument.parse(xmlString);
    } on XmlException catch (e) {
      throw FileCorruptedError('bad xml: $e.toString()');
    }

    return _xmlToDB(
      header: KdbxHeader.create(credentials: credentials),
      xml: xml,
      binaryTime: false,
    );
  }

  /// Saves the database to a bytes list.
  Future<List<int>> save() async {
    header.generateSalts();
    final version = header.version.$1;

    return header.bytes +
        await switch (version) {
          3 => _v3Bytes,
          4 => _v4Bytes,
          _ => throw UnsupportedValueError('bad version: $version')
        };
  }

  /// Saves the database as XML string.
  String exportToXmlString({bool pretty = false}) => _buildXml(
        exportXml: true,
        binaryTime: false,
      ).toXmlString(pretty: pretty);

  /// Set the file version to a specified number.
  set version((int, int) version) {
    meta.settingsChanged = KdbxTime.now();
    header.version = version;
  }

  /// The database binaries.
  KdbxBinaries get binaries => header.binaries;

  /// The database groups.
  List<KdbxGroup> get groups => _groups;

  /// The database deleted objects.
  Map<KdbxUuid, KdbxTime> get deletedObjects => _deletedObjects;

  /// Set file key derivation function to [kdf] id.
  set kdf(String kdf) {
    meta.settingsChanged = KdbxTime.now();
    header.kdf = kdf;
  }

  /// The database recycle bin group.
  KdbxGroup? get recycleBin => meta.recycleBinEnabled
      ? getGroup(uuid: meta.recycleBinUuid) ?? _createRecycleBin()
      : null;

  /// Gets the root group
  KdbxGroup get root {
    if (_groups.isEmpty) {
      throw InvalidStateError('no root group');
    }

    return _groups.first;
  }

  /// The edit state tombstones which are necessary for successful merge.
  /// The replica must save this state on the database save
  /// and set it on the database open.
  KdbxEditState get localEditState => KdbxEditState.empty()
    ..meta = meta.editState
    ..entries.addEntries(
      root.allEntries.map(
        (e) => MapEntry(e.uuid, e.editState),
      ),
    );

  set localEditState(KdbxEditState editingState) {
    meta.editState = editingState.meta;

    for (var e in root.allEntries) {
      final state = editingState.entries[e.uuid];
      if (state != null) {
        e.editState = state;
      }
    }
  }

  /// Removes editing state tombstones.
  /// Immediately after successful upstream push the replica must:
  ///  - call this method;
  ///  - discard any previous saved state.
  void clearLocalEditState() {
    meta.editState = KdbxMetaEditState.empty();

    for (var e in root.allEntries) {
      e.editState = KdbxEntryEditState.empty();
    }
  }

  /// Upgrades the database to latest KDBX version.
  upgrade() => version = KdbxHeader.defaultVersion;

  /// Creates a new group with [name] and [icon] to a [parent].
  KdbxGroup createGroup({
    required KdbxGroup parent,
    required String name,
    KdbxIcon icon = KdbxIcon.folder,
  }) {
    final subGroup = KdbxGroup.create(
      name: name,
      parent: parent,
      icon: icon,
      id: KdbxUuid.random(
        prohibited: root.allItems.map((e) => e.uuid).toSet(),
      ),
    );
    parent.groups.add(subGroup);
    return subGroup;
  }

  /// Creates a new entry with [icon] to a [parent].
  KdbxEntry createEntry({
    required KdbxGroup parent,
    KdbxIcon icon = KdbxIcon.folder,
  }) {
    final entry = KdbxEntry.create(
      parent: parent,
      meta: meta,
      id: KdbxUuid.random(
        prohibited: root.allItems.map((e) => e.uuid).toSet(),
      ),
    );
    parent.entries.add(entry);
    return entry;
  }

  /// Returns a group by [uuid] or null if not found.
  KdbxGroup? getGroup({required KdbxUuid? uuid}) => groups
      .map((g) => g.allGroups.firstWhereOrNull((g) => g.uuid == uuid))
      .firstWhereOrNull((g) => g != null);

  /// Moves an [item] from parent group to a [target] group at [index] position.
  /// In case [target] is null, the [item] will be removed.
  move({required KdbxItem item, KdbxGroup? target, int? index}) {
    if (item is KdbxGroup && item.allGroups.contains(target)) {
      throw InvalidStateError('attempt to move a group to it\'s child');
    }

    final parent = item.parent;
    if (parent != null) {
      (item is KdbxEntry ? parent.entries : parent.groups).remove(item);

      if (parent != target) {
        item.previousParent = parent.uuid;
        item.parent = target;
      }
    }

    final now = KdbxTime.now();

    if (target != null) {
      final to = (item is KdbxEntry ? target.entries : target.groups);
      to.insert(index ?? to.length, item);
    } else {
      deletedObjects.addAll({
        if (item is KdbxGroup) ...{
          for (var i in item.allItems) i.uuid: (now)
        } else
          item.uuid: now
      });
    }

    item.times.locationChange = now;
  }

  /// Removes an [item] from parent group.
  /// Depending on settings, removes either to recycle bin or completely.
  remove(KdbxItem item) {
    final rb = recycleBin;
    final isInRecycleBin = rb != null && rb.allItems.contains(item);
    move(item: item, target: isInRecycleBin ? null : rb);
  }

  /// Performs database cleanup.
  /// Removes extra [history] if it is true and doesn't match defined rules, e.g. records number.
  /// Remove unused custom [icons] if it is true.
  /// Remove unused [binaries] if it is true.
  cleanup({
    bool history = false,
    bool icons = false,
    bool binaries = false,
  }) {
    final now = KdbxTime.now();
    final historyMaxItems = history ? meta.historyMaxItems : null;

    final usedCustomIcons = <KdbxUuid>{};
    final usedBinaries = <BinaryReference>[];

    processEntry(KdbxEntry entry) {
      final icon = entry.customIcon;
      if (icon != null) {
        usedCustomIcons.add(icon);
      }
      usedBinaries.addAll(entry.binaries.values);
    }

    for (final item in root.allItems) {
      if (item is KdbxEntry) {
        if (historyMaxItems != null && item.history.length > historyMaxItems) {
          item.removeFromHistory(
            start: 0,
            end: item.history.length - historyMaxItems,
          );
        }

        processEntry(item);

        for (final entry in item.history) {
          processEntry(entry);
        }
      } else {
        final icon = item.customIcon;
        if (icon != null) {
          usedCustomIcons.add(icon);
        }
      }
    }

    if (icons) {
      final toRemove = meta.customIcons.entries
          .where((element) => !usedCustomIcons.contains(element.key))
          .map((e) => e.key);

      deletedObjects.addAll({for (var id in toRemove) id: now});
      meta.customIcons.removeWhere((key, _) => toRemove.contains(key));
    }

    if (binaries) {
      header.binaries.cleanup(usedBinaries);
    }
  }

  /// Merges a [remote] database to this database.
  /// Suggested use case:
  ///  - open a local database;
  ///  - get a remote database somehow and open in;
  ///  - merge the remote into the local database: local.merge(remote);
  ///  - close the remote database.
  // TODO: check if any parts are copied by reference and copy it by value.
  merge(KdbxDatabase remote) {
    if (root.uuid != remote.root.uuid) {
      throw MergeError('root group is different');
    }

    final objectMap = _getObjectMap();

    for (final rem in remote.deletedObjects.entries) {
      if (!objectMap.deleted.contains(rem.key)) {
        deletedObjects[rem.key] = rem.value;
        objectMap.deleted.add(rem.key);
      }
    }

    for (final remoteBinary in remote.binaries.all) {
      if (!binaries.contains(remoteBinary)) {
        binaries.add(remoteBinary);
      }
    }

    final remoteObjectMap = remote._getObjectMap();
    objectMap.remoteItems = remoteObjectMap.items;

    meta.merge(remote.meta);
    root.merge(objectMap);

    cleanup(history: true, icons: true, binaries: true);
  }

  /// Imports an [entry] from [other] database to the [target] group.
  /// Returns the new entry.
  KdbxEntry importEntry({
    required KdbxEntry entry,
    required KdbxGroup target,
    required KdbxDatabase other,
  }) {
    final newEntry = KdbxEntry.copyFrom(
      entry,
      KdbxUuid.random(
        prohibited: root.allItems.map((e) => e.uuid).toSet(),
      ),
    );
    newEntry.parent = target;
    target.entries.add(newEntry);
    newEntry.history.addAll([
      ...entry.history.map((e) => KdbxEntry.copyFrom(e, newEntry.uuid)),
      newEntry
    ]);

    final binaries = <KdbxDataBinary>{};
    final customIcons = <KdbxUuid>{};

    for (final e in newEntry.history) {
      final icon = e.customIcon;
      if (icon != null) {
        customIcons.add(icon);
      }

      binaries.addAll(e.binaries.values
          .map((ref) => header.binaries.getByRef(ref))
          .nonNulls);
    }

    for (final binary in binaries) {
      if (!header.binaries.contains(binary)) {
        header.binaries.add(binary);
      }
    }

    final prohibited = meta.customIcons.keys.toSet();

    for (final customIconId in customIcons) {
      final customIcon = other.meta.customIcons[customIconId];
      if (customIcon != null) {
        final id = prohibited.contains(customIconId)
            ? KdbxUuid.random(prohibited: prohibited)
            : customIconId;
        meta.customIcons[id] = customIcon;
      }
    }

    newEntry.times.touch();
    return newEntry;
  }

  static Future<KdbxDatabase> _loadV3({
    required BytesReader reader,
    required KdbxHeader header,
  }) async {
    final xml = XmlDocument.parse(await _decryptXmlV3(
      bytes: reader.readBytesToEnd(),
      header: header,
    ));
    return _xmlToDB(
      xml: xml,
      header: header,
      binaryTime: false,
    );
  }

  static Future<KdbxDatabase> _loadV4({
    required BytesReader reader,
    required KdbxHeader header,
  }) async {
    final headerBytes = reader.past;

    final expectedHeaderSha = reader.readBytes(header.hash.length);
    if (!ListEquality().equals(expectedHeaderSha, header.hash)) {
      throw FileCorruptedError('header hash mismatch');
    }

    final (cipherKey, hmacKey, hmac) = header.computeKeysV4(headerBytes);

    final expectedHeaderHmac = reader.readBytes(hmac.length);
    if (!ListEquality().equals(expectedHeaderHmac, hmac)) {
      throw InvalidCredentialsError('invalid key');
    }

    final content = HmacBlockTransform.decrypt(
      data: reader.readBytesToEnd(),
      key: hmacKey,
    );
    CryptoUtils.wipeData(hmacKey);

    var data = await _transformData(
      header: header,
      data: content,
      cipherKey: cipherKey,
      encrypt: false,
    );

    CryptoUtils.wipeData(cipherKey);

    if (header.compression == CompressionAlgorithm.gzip) {
      data = ZLibDecoder().decodeBytes(data);
    }

    reader = BytesReader(data);
    header.readInnerHeader(reader);
    final xml = XmlDocument.parse(
      utf8.decode(
        reader.readBytesToEnd(),
      ),
    );

    return _xmlToDB(header: header, xml: xml, binaryTime: true);
  }

  Future<List<int>> get _v3Bytes {
    final xml = _buildXml(exportXml: false, binaryTime: false);
    return _getXmlV3Bytes(xml);
  }

  Future<List<int>> get _v4Bytes async {
    final xml = _buildXml(exportXml: false, binaryTime: true);

    final (cipherKey, hmacKey, hmac) = header.computeKeysV4();

    final writer = BytesWriter();
    writer.writeBytes(header.hash);
    writer.writeBytes(hmac);

    final innerHeaderData = header.innerBytes;
    final xmlData = utf8.encode(xml.toXmlString());
    var data = innerHeaderData + xmlData;
    CryptoUtils.wipeData(xmlData);
    CryptoUtils.wipeData(innerHeaderData);

    if (header.compression == CompressionAlgorithm.gzip) {
      data = GZipEncoder().encodeBytes(data);
    }

    data = await _transformData(
      header: header,
      data: data,
      cipherKey: cipherKey,
      encrypt: true,
    );
    CryptoUtils.wipeData(cipherKey);

    data = HmacBlockTransform.encrypt(data: data, key: hmacKey);
    CryptoUtils.wipeData(hmacKey);
    writer.writeBytes(data);

    return writer.bytes;
  }

  XmlDocument _buildXml({required bool exportXml, required bool binaryTime}) {
    final deletedObjectsNode = XmlElement(
      XmlName(XmlElem.deletedObjects),
      [],
      deletedObjects.entries.map(
        (e) => XmlUtils.createElement(
            name: XmlElem.deletedObject,
            children: [
              (XmlElem.uuid, e.key),
              (XmlElem.deletionTime, e.value),
            ],
            binaryTime: binaryTime),
      ),
    );

    final rootNode = XmlElement(
      XmlName(XmlElem.root),
      [],
      [
        ...groups.map((e) => e.toXml(
              header: header,
              exportXml: exportXml,
              binaryTime: binaryTime,
              includeHistory: true,
            )),
        deletedObjectsNode,
      ],
    );

    return XmlUtils.create(XmlElem.docNode)
      ..rootElement.children.addAll(
        [
          meta.toXml(
            header: header,
            exportXml: exportXml,
            binaryTime: binaryTime,
          ),
          rootNode,
        ],
      );
  }

  static Future<String> _decryptXmlV3({
    required List<int> bytes,
    required KdbxHeader header,
  }) async {
    final masterKey = await header.masterKeyV3;
    var data = await _transformData(
      header: header,
      data: bytes,
      cipherKey: masterKey,
      encrypt: false,
    );
    CryptoUtils.wipeData(masterKey);

    data = _trimStartBytesV3(data: data, header: header);
    data = HashedBlockTransform.decrypt(data);

    if (header.compression == CompressionAlgorithm.gzip) {
      data = GZipDecoder().decodeBytes(data);
    }

    return utf8.decode(data);
  }

  Future<List<int>> _getXmlV3Bytes(XmlDocument xml) async {
    var data = utf8.encode(xml.toXmlString()).toList();

    if (header.compression == CompressionAlgorithm.gzip) {
      data = GZipEncoder().encodeBytes(data);
    }

    data = HashedBlockTransform.encrypt(data);

    final ssb = header.streamStartBytes;
    if (ssb == null) {
      throw InvalidStateError('no header start bytes');
    }

    data = ssb + data;

    final masterKey = await header.masterKeyV3;
    data = await _transformData(
      header: header,
      data: data,
      cipherKey: masterKey,
      encrypt: true,
    );
    CryptoUtils.wipeData(masterKey);

    return data;
  }

  static List<int> _trimStartBytesV3({
    required List<int> data,
    required KdbxHeader header,
  }) {
    if (header.streamStartBytes == null) {
      throw FileCorruptedError('no stream start bytes');
    }

    final length = header.streamStartBytes?.length ?? 0;
    if (data.length < length) {
      throw FileCorruptedError('short start bytes');
    }

    if (!ListEquality()
        .equals(data.slice(0, length), header.streamStartBytes)) {
      throw InvalidCredentialsError('invalid key');
    }

    return data.slice(length);
  }

  static Future<List<int>> _transformData({
    required KdbxHeader header,
    required List<int> data,
    required List<int> cipherKey,
    required encrypt,
  }) async {
    final cipherId = header.dataCipherUuid;
    if (cipherId == null) {
      throw FileCorruptedError('no cipher id');
    }

    final iv = header.encryptionIV;
    if (iv == null) {
      throw FileCorruptedError('no encryption IV');
    }

    try {
      return await switch (cipherId.string) {
        CipherId.aes => CryptoUtils.transformAes(
            data: data,
            key: cipherKey,
            iv: iv,
            encrypt: encrypt,
          ),
        CipherId.chaCha20 => CryptoUtils.transformChaCha20(
            data: data,
            key: cipherKey,
            iv: iv,
          ),
        _ => throw UnsupportedValueError('unsupported cipher')
      };
    } catch (_) {
      throw InvalidCredentialsError('invalid key');
    }
  }

  /// Creates a root group, if it is absent.
  _createRoot(String name) {
    if (_groups.isEmpty) {
      _groups.add(KdbxGroup.create(
        name: name,
        icon: KdbxIcon.folderOpen,
        id: KdbxUuid.random(),
      ));
    }
  }

  /// Creates a recycle bin group.
  KdbxGroup _createRecycleBin() {
    final recycleBin = KdbxGroup.create(
      name: Defaults.recycleBinName,
      icon: KdbxIcon.trashBin,
      id: KdbxUuid.random(prohibited: root.allItems.map((e) => e.uuid).toSet()),
      parent: root,
      enableAutoType: false,
      enableSearching: false,
    );

    root.groups.add(recycleBin);
    meta.recycleBinUuid = recycleBin.uuid;

    return recycleBin;
  }

  static KdbxDatabase _xmlToDB({
    required XmlDocument xml,
    required KdbxHeader header,
    required bool binaryTime,
  }) {
    final meta = _xmlToMeta(header: header, xml: xml, binaryTime: binaryTime);
    final db = KdbxDatabase._(header: header, meta: meta);
    db._parseRoot(xml: xml, binaryTime: binaryTime);
    return db;
  }

  _parseRoot({required XmlDocument xml, required bool binaryTime}) {
    final doc = xml.rootElement;

    if (doc.name.local != XmlElem.docNode) {
      throw FileCorruptedError('bad xml document');
    }

    final root = XmlUtils.getChildNode(
      doc,
      XmlElem.root,
      'no root node',
    );

    for (final e in root.childElements) {
      switch (e.qualifiedName) {
        case XmlElem.group:
          _groups.add(KdbxGroup.fromXml(e, header, binaryTime));
        case XmlElem.deletedObjects:
          _deletedObjects.addAll(_readDeletedObjects(e, binaryTime));
      }
    }
  }

  static KdbxMeta _xmlToMeta({
    required KdbxHeader header,
    required XmlDocument xml,
    required bool binaryTime,
  }) {
    final node = xml.rootElement.childElements.firstWhere(
      (element) => element.qualifiedName == XmlElem.meta,
      orElse: () => throw FileCorruptedError('no meta node'),
    );

    return KdbxMeta.fromXml(
      node: node,
      header: header,
      binaryTime: binaryTime,
    );
  }

  static Map<KdbxUuid, KdbxTime> _readDeletedObjects(
    XmlNode node,
    bool binaryTime,
  ) =>
      Map.fromEntries(
        node.childElements
            .where((e) => e.qualifiedName == XmlElem.deletedObject)
            .map(
          (e) {
            final view = XmlUtils.getChildrenView(e);
            final uuid = view.firstWhereOrNull((e) => e.$1 == XmlElem.uuid)?.$2;
            final time =
                view.firstWhereOrNull((e) => e.$1 == XmlElem.deletionTime)?.$2;

            return (uuid != null && time != null)
                ? MapEntry(KdbxUuid.fromString(uuid),
                    KdbxTime.fromXmlText(text: time, isBinary: binaryTime))
                : null;
          },
        ).nonNulls,
      );

  MergeObjectMap _getObjectMap() {
    final objectMap = MergeObjectMap();

    for (final item in root.allItems) {
      if (objectMap.items.containsKey(item.uuid)) {
        throw MergeError('duplicate: ${item.uuid}');
      }

      objectMap.items[item.uuid] = item;
    }

    for (final deletedObject in deletedObjects.entries) {
      objectMap.deleted.add(deletedObject.key);
    }

    return objectMap;
  }
}
