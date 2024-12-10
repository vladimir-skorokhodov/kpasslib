import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../utils/xml_utils.dart';

/// An edit state of the [KdbxMeta]
class KdbxMetaEditState {
  var _maintenanceHistoryDaysChanged = KdbxTime();
  var _colorChanged = KdbxTime();
  var _keyChangeRecChanged = KdbxTime();
  var _keyChangeForceChanged = KdbxTime();
  var _historyMaxItemsChanged = KdbxTime();
  var _historyMaxSizeChanged = KdbxTime();
  var _lastSelectedGroupChanged = KdbxTime();
  var _lastTopVisibleGroupChanged = KdbxTime();
  var _memoryProtectionChanged = KdbxTime();

  /// Constructs an empty meta edit state.
  KdbxMetaEditState.empty();

  /// Constructs a [KdbxMetaEditState] from the XML [node].
  factory KdbxMetaEditState.fromXml(XmlNode node) {
    final state = KdbxMetaEditState.empty();

    for (var e in node.childElements) {
      final time = KdbxTime.fromXmlText(
        text: e.innerText,
        isBinary: true,
      );
      switch (e.qualifiedName) {
        case XmlElem.maintenanceHistoryDaysChanged:
          state._maintenanceHistoryDaysChanged = time;
        case XmlElem.colorChanged:
          state._colorChanged = time;
        case XmlElem.keyChangeRecChanged:
          state._keyChangeRecChanged = time;
        case XmlElem.keyChangeForceChanged:
          state._keyChangeForceChanged = time;
        case XmlElem.historyMaxItemsChanged:
          state._historyMaxItemsChanged = time;
        case XmlElem.historyMaxSizeChanged:
          state._historyMaxSizeChanged = time;
        case XmlElem.lastSelectedGroupChanged:
          state._lastSelectedGroupChanged = time;
        case XmlElem.lastTopVisibleGroupChanged:
          state._lastTopVisibleGroupChanged = time;
        case XmlElem.memoryProtectionChanged:
          state._memoryProtectionChanged = time;
      }
    }

    return state;
  }

  /// Serializes the state to an XML node.
  XmlNode toXml() {
    return XmlUtils.createElement(
        name: XmlElem.metaEditState,
        children: [
          (
            XmlElem.maintenanceHistoryDaysChanged,
            _maintenanceHistoryDaysChanged
          ),
          (XmlElem.colorChanged, _colorChanged),
          (XmlElem.keyChangeRecChanged, _keyChangeRecChanged),
          (XmlElem.keyChangeForceChanged, _keyChangeForceChanged),
          (XmlElem.historyMaxItemsChanged, _historyMaxItemsChanged),
          (XmlElem.historyMaxSizeChanged, _historyMaxSizeChanged),
          (XmlElem.lastSelectedGroupChanged, _lastSelectedGroupChanged),
          (XmlElem.lastTopVisibleGroupChanged, _lastTopVisibleGroupChanged),
          (XmlElem.memoryProtectionChanged, _memoryProtectionChanged),
        ],
        binaryTime: true);
  }
}

/// A memory protection flags.
class KdbxMemoryProtection {
  /// Whether title should be protected.
  bool? title;

  /// Whether user name should be protected.
  bool? userName;

  /// Whether password should be protected.
  bool? password;

  /// Whether url should be protected.
  bool? url;

  /// Whether notes should be protected.
  bool? notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KdbxMemoryProtection &&
          title == other.title &&
          userName == other.userName &&
          password == other.password &&
          url == other.url &&
          notes == other.notes;

  @override
  int get hashCode => Object.hashAll([title, userName, password, url, notes]);
}

/// A custom icon.
class KdbxCustomIcon {
  /// The custom icon data.
  List<int> data;

  /// The custom icon name.
  String? name;

  /// The custom icon modification time.
  KdbxTime modified;

  /// Constructs a custom icon.
  KdbxCustomIcon({
    required this.data,
    this.name,
    KdbxTime? modified,
  }) : modified = modified ?? KdbxTime();
}

/// Represents KDBX meta information type
class KdbxMeta {
  /// The KDBX file generator name.
  String? generator;

  /// The custom icons collection name.
  Map<KdbxUuid, KdbxCustomIcon> customIcons = {};

  /// The custom data.
  var customData = KdbxCustomData();

  /// The settings last change time.
  var settingsChanged = KdbxTime();

  /// The name last change time.
  var nameChanged = KdbxTime();

  /// The description last change time.
  var descriptionChanged = KdbxTime();

  /// The default user last change time.
  var defaultUserChanged = KdbxTime();

  /// The master key last change time.
  var keyChanged = KdbxTime();

  /// The entry templates group last change time.
  var entryTemplatesGroupChanged = KdbxTime();

  /// The recycle bin last change time.
  var recycleBinChanged = KdbxTime();

  /// The edit state.
  var editState = KdbxMetaEditState.empty();

  var _memoryProtection = KdbxMemoryProtection();

  String _name = '';
  KdbxUuid? _lastSelectedGroup;
  KdbxUuid? _lastTopVisibleGroup;
  bool _recycleBinEnabled = true;
  KdbxUuid? _recycleBinUuid;

  String? _defaultUser;
  String? _description;
  String? _color;
  int? _maintenanceHistoryDays;
  int? _keyChangeRec;
  int? _keyChangeForce;
  KdbxUuid? _entryTemplatesGroup;
  int? _historyMaxItems = Defaults.historyMaxItems;
  int? _historyMaxSize = Defaults.historyMaxSize;

  /// Constructs a [KdbxMeta] with default values.
  KdbxMeta.create();

  /// Constructs a [KdbxMeta] from XML [node].
  factory KdbxMeta.fromXml({
    required XmlNode node,
    required KdbxHeader header,
    required bool binaryTime,
  }) {
    final meta = KdbxMeta.create();

    for (var element in node.childElements) {
      if (element.qualifiedName.isNotEmpty) {
        meta._readNode(element, header, binaryTime);
      }
    }

    return meta;
  }

  ///Serializes the meta to an XML node.
  XmlNode toXml({
    required KdbxHeader header,
    required bool exportXml,
    required bool binaryTime,
  }) {
    final metaNode = XmlUtils.createElement(
        name: XmlElem.meta,
        children: [
          (XmlElem.generator, generator = Defaults.generator),
          if (header.version.$1 < 4)
            (XmlElem.headerHash, header.hash)
          else
            (XmlElem.settingsChanged, settingsChanged),
          (XmlElem.dbName, _name),
          (XmlElem.dbNameChanged, nameChanged),
          (XmlElem.dbDesc, _description),
          (XmlElem.dbDescChanged, descriptionChanged),
          (XmlElem.dbDefaultUser, defaultUser),
          (XmlElem.dbDefaultUserChanged, defaultUserChanged),
          (XmlElem.dbMaintenanceHistoryDays, _maintenanceHistoryDays),
          (XmlElem.dbColor, _color),
          (XmlElem.dbKeyChanged, keyChanged),
          (XmlElem.dbKeyChangeRec, _keyChangeRec),
          (XmlElem.dbKeyChangeForce, _keyChangeForce)
        ],
        binaryTime: binaryTime);

    metaNode.children.addAll([_getMemoryProtection(), _getCustomIcons(header)]);

    XmlUtils.addChildren(
        parent: metaNode,
        children: [
          (XmlElem.recycleBinEnabled, recycleBinEnabled),
          (XmlElem.recycleBinUuid, recycleBinUuid),
          (XmlElem.recycleBinChanged, recycleBinChanged),
          (XmlElem.entryTemplatesGroup, entryTemplatesGroup),
          (XmlElem.entryTemplatesGroupChanged, entryTemplatesGroupChanged),
          (XmlElem.historyMaxItems, _historyMaxItems),
          (XmlElem.historyMaxSize, _historyMaxSize),
          (XmlElem.lastSelectedGroup, _lastSelectedGroup),
          (XmlElem.lastTopVisibleGroup, _lastTopVisibleGroup)
        ],
        binaryTime: binaryTime);

    final customDataNode = customData.toXml(
        includeModificationTime: header.versionIsAtLeast(4, 1));

    metaNode.children.addAll([
      if (exportXml || header.version.$1 < 4)
        header.binaries.toXml(exportXml ? null : header),
      if (customDataNode != null) customDataNode
    ]);

    return metaNode;
  }

  /// The database name.
  String get name => _name;
  set name(String value) {
    if (value != _name) {
      _name = value;
      nameChanged = KdbxTime.now();
    }
  }

  /// The database description.
  String? get description => _description;
  set description(String? value) {
    if (value != _description) {
      _description = value;
      descriptionChanged = KdbxTime.now();
    }
  }

  /// The last selected group ID.
  KdbxUuid? get lastSelectedGroup => _lastSelectedGroup;
  set lastSelectedGroup(KdbxUuid? value) {
    if (value != _lastSelectedGroup) {
      _lastSelectedGroup = value;
      editState._lastSelectedGroupChanged = KdbxTime.now();
    }
  }

  /// The last top visible group ID.
  KdbxUuid? get lastTopVisibleGroup => _lastTopVisibleGroup;
  set lastTopVisibleGroup(KdbxUuid? value) {
    if (value != _lastTopVisibleGroup) {
      _lastTopVisibleGroup = value;
      editState._lastTopVisibleGroupChanged = KdbxTime.now();
    }
  }

  /// Whether recycle bin is enabled.
  bool get recycleBinEnabled => _recycleBinEnabled;
  set recycleBinEnabled(bool value) {
    if (value != _recycleBinEnabled) {
      _recycleBinEnabled = value;
      recycleBinChanged = KdbxTime.now();
    }
  }

  /// The recycle bin group ID.
  KdbxUuid? get recycleBinUuid => _recycleBinUuid;
  set recycleBinUuid(KdbxUuid? value) {
    if (value != _recycleBinUuid) {
      _recycleBinUuid = value;
      recycleBinChanged = KdbxTime.now();
    }
  }

  /// The memory protection.
  KdbxMemoryProtection get memoryProtection => _memoryProtection;
  set memoryProtection(KdbxMemoryProtection value) {
    if (value != _memoryProtection) {
      _memoryProtection = value;
      editState._memoryProtectionChanged = KdbxTime.now();
    }
  }

  /// The default user name.
  String? get defaultUser => _defaultUser;
  set defaultUser(String? value) {
    if (value != _defaultUser) {
      _defaultUser = value;
      defaultUserChanged = KdbxTime.now();
    }
  }

  /// The entry templates group ID.
  KdbxUuid? get entryTemplatesGroup => _entryTemplatesGroup;
  set entryTemplatesGroup(KdbxUuid? value) {
    if (value != _entryTemplatesGroup) {
      _entryTemplatesGroup = value;
      entryTemplatesGroupChanged = KdbxTime.now();
    }
  }

  /// The amount of maintenance history days.
  int? get maintenanceHistoryDays => _maintenanceHistoryDays;
  set maintenanceHistoryDays(int? value) {
    if (value != _maintenanceHistoryDays) {
      _maintenanceHistoryDays = value;
      editState._maintenanceHistoryDaysChanged = KdbxTime.now();
    }
  }

  /// The recommended period of key changes.
  int? get keyChangeRec => _keyChangeRec;
  set keyChangeRec(int? value) {
    if (value != _keyChangeRec) {
      _keyChangeRec = value;
      editState._keyChangeRecChanged = KdbxTime.now();
    }
  }

  /// The required period of key changes.
  int? get keyChangeForce => _keyChangeForce;
  set keyChangeForce(int? value) {
    if (value != _keyChangeForce) {
      _keyChangeForce = value;
      editState._keyChangeForceChanged = KdbxTime.now();
    }
  }

  /// The maximal items of the history.
  int? get historyMaxItems => _historyMaxItems;
  set historyMaxItems(int? value) {
    if (value != _historyMaxItems) {
      _historyMaxItems = value;
      editState._historyMaxItemsChanged = KdbxTime.now();
    }
  }

  /// The maximal size of history in bytes.
  int? get historyMaxSize => _historyMaxSize;
  set historyMaxSize(int? value) {
    if (value != _historyMaxSize) {
      _historyMaxSize = value;
      editState._historyMaxSizeChanged = KdbxTime.now();
    }
  }

  /// The database color.
  String? get color => _color;
  set color(String? value) {
    if (value != _color) {
      _color = value;
      editState._colorChanged = KdbxTime.now();
    }
  }

  ///Merges the [remote] meta into this meta.
  merge(KdbxMeta remote) {
    if (remote.nameChanged.isAfter(nameChanged)) {
      _name = remote._name;
      nameChanged = remote.nameChanged;
    }

    if (remote.descriptionChanged.isAfter(descriptionChanged)) {
      _description = remote._description;
      descriptionChanged = remote.descriptionChanged;
    }

    if (remote.defaultUserChanged.isAfter(defaultUserChanged)) {
      _defaultUser = remote._defaultUser;
      defaultUserChanged = remote.defaultUserChanged;
    }

    if (remote.keyChanged.isAfter(keyChanged)) {
      keyChanged = remote.keyChanged;
    }

    if (remote.settingsChanged.isAfter(settingsChanged)) {
      settingsChanged = remote.settingsChanged;
    }

    if (remote.recycleBinChanged.isAfter(recycleBinChanged)) {
      _recycleBinEnabled = remote._recycleBinEnabled;
      _recycleBinUuid = remote._recycleBinUuid;
      recycleBinChanged = remote.recycleBinChanged;
    }

    if (remote.entryTemplatesGroupChanged.isAfter(entryTemplatesGroupChanged)) {
      _entryTemplatesGroup = remote._entryTemplatesGroup;
      entryTemplatesGroupChanged = remote.entryTemplatesGroupChanged;
    }

    remote.customData.map.forEach((key, value) {
      final remoteValue = customData.map[key];
      if (remoteValue == null ||
          value.modification.isAfter(remoteValue.modification)) {
        customData.map[key] = value;
      }
    });

    remote.customIcons.forEach((key, value) {
      final ci = customIcons[key];
      if (ci == null || value.modified.isAfter(ci.modified)) {
        customIcons[key] = value;
      }
    });

    if (editState._historyMaxItemsChanged.time == null) {
      _historyMaxItems = remote._historyMaxItems;
    }

    if (editState._historyMaxSizeChanged.time == null) {
      _historyMaxSize = remote._historyMaxSize;
    }

    if (editState._keyChangeRecChanged.time == null) {
      _keyChangeRec = remote._keyChangeRec;
    }

    if (editState._keyChangeForceChanged.time == null) {
      _keyChangeForce = remote._keyChangeForce;
    }

    if (editState._maintenanceHistoryDaysChanged.time == null) {
      _maintenanceHistoryDays = remote._maintenanceHistoryDays;
    }

    if (editState._colorChanged.time == null) {
      _color = remote._color;
    }
  }

  _readNode(XmlElement node, KdbxHeader header, bool binaryTime) {
    switch (node.qualifiedName) {
      case XmlElem.generator:
        generator = node.innerText;
      case XmlElem.headerHash:
        final headerHash = base64.decode(node.innerText);
        if (!ListEquality().equals(headerHash, header.hash)) {
          throw FileCorruptedError('header hash mismatch');
        }
      case XmlElem.settingsChanged:
        settingsChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.dbName:
        _name = node.innerText;
      case XmlElem.dbNameChanged:
        nameChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.dbDesc:
        _description = node.innerText;
      case XmlElem.dbDescChanged:
        descriptionChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.dbDefaultUser:
        _defaultUser = node.innerText;
      case XmlElem.dbDefaultUserChanged:
        defaultUserChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.dbMaintenanceHistoryDays:
        try {
          _maintenanceHistoryDays = int.tryParse(node.innerText);
        } on FormatException catch (e) {
          throw FileCorruptedError(
              'cannot read maintenance history days: $e.message');
        }
      case XmlElem.dbColor:
        _color = node.innerText;
      case XmlElem.dbKeyChanged:
        keyChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.dbKeyChangeRec:
        _keyChangeRec = int.tryParse(node.innerText);
      case XmlElem.dbKeyChangeForce:
        _keyChangeForce = int.tryParse(node.innerText);
      case XmlElem.recycleBinEnabled:
        _recycleBinEnabled = XmlUtils.getBoolean(node) ?? true;
      case XmlElem.recycleBinUuid:
        _recycleBinUuid = KdbxUuid.fromString(node.innerText);
      case XmlElem.recycleBinChanged:
        recycleBinChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.entryTemplatesGroup:
        _entryTemplatesGroup = KdbxUuid.fromString(node.innerText);
      case XmlElem.entryTemplatesGroupChanged:
        entryTemplatesGroupChanged =
            KdbxTime.fromXmlText(text: node.innerText, isBinary: binaryTime);
      case XmlElem.historyMaxItems:
        _historyMaxItems = int.tryParse(node.innerText);
      case XmlElem.historyMaxSize:
        _historyMaxSize = int.tryParse(node.innerText);
      case XmlElem.lastSelectedGroup:
        _lastSelectedGroup = KdbxUuid.fromString(node.innerText);
      case XmlElem.lastTopVisibleGroup:
        _lastTopVisibleGroup = KdbxUuid.fromString(node.innerText);
      case XmlElem.memoryProtection:
        _readMemoryProtection(node);
      case XmlElem.customIcons:
        _readCustomIcons(node);
      case XmlElem.binaries:
        header.binaries.readFromXml(element: node, header: header);
      case XmlElem.customData:
        customData = KdbxCustomData.fromXml(node);
    }
  }

  _readMemoryProtection(XmlElement node) {
    for (var element in node.childElements) {
      switch (element.qualifiedName) {
        case XmlElem.protTitle:
          memoryProtection.title = XmlUtils.getBoolean(element);
        case XmlElem.protUserName:
          memoryProtection.userName = XmlUtils.getBoolean(element);
        case XmlElem.protPassword:
          memoryProtection.password = XmlUtils.getBoolean(element);
        case XmlElem.protUrl:
          memoryProtection.url = XmlUtils.getBoolean(element);
        case XmlElem.protNotes:
          memoryProtection.notes = XmlUtils.getBoolean(element);
      }
    }
  }

  _getMemoryProtection() =>
      XmlUtils.createElement(name: XmlElem.memoryProtection, children: [
        (XmlElem.protTitle, memoryProtection.title),
        (XmlElem.protUserName, memoryProtection.userName),
        (XmlElem.protPassword, memoryProtection.password),
        (XmlElem.protUrl, memoryProtection.url),
        (XmlElem.protNotes, memoryProtection.notes)
      ]);

  _readCustomIcons(XmlElement node) {
    for (var element in node.childElements) {
      if (element.qualifiedName == XmlElem.customIconItem) {
        _readCustomIcon(element);
      }
    }
  }

  _readCustomIcon(XmlElement node) {
    KdbxUuid? uuid;
    List<int>? data;
    String? name;
    KdbxTime? lastModified;

    for (var element in node.childElements) {
      switch (element.qualifiedName) {
        case XmlElem.customIconItemID:
          uuid = KdbxUuid.fromString(element.innerText);
        case XmlElem.customIconItemData:
          data = base64.decode(element.innerText);
        case XmlElem.customIconItemName:
          name = element.innerText;
        case XmlElem.lastModTime:
          lastModified =
              KdbxTime.fromXmlText(text: element.innerText, isBinary: true);
      }
    }

    if (uuid != null && data != null) {
      customIcons[uuid] = KdbxCustomIcon(
        data: data,
        name: name,
        modified: lastModified,
      );
    }
  }

  _getCustomIcons(KdbxHeader header) => XmlElement(
        XmlName(XmlElem.customIcons),
        [],
        customIcons.entries.map(
          (e) => XmlUtils.createElement(
              name: XmlElem.customIconItem,
              children: [
                (XmlElem.customIconItemID, e.key),
                (XmlElem.customIconItemData, e.value.data),
                if (header.versionIsAtLeast(4, 1)) ...[
                  (XmlElem.customIconItemName, e.value.name),
                  (XmlElem.lastModTime, e.value.modified)
                ]
              ],
              binaryTime: true),
        ),
      );
}
