import 'dart:collection';
import 'dart:convert';

import 'package:kpasslib/kpasslib.dart';
import 'package:xml/xml.dart';

import '../utils/merge_utils.dart';
import '../utils/xml_utils.dart';
import 'kdbx_autotype.dart';

/// A text field of an [KdbxEntry].
abstract class KdbxTextField {
  KdbxTextField._();

  /// Constructs a [KdbxTextField] from provided [text].
  /// Returns [ProtectedTextField] if [protected] is true,
  /// Otherwise – [PlainTextField].
  factory KdbxTextField.fromText({
    required String text,
    bool? protected = false,
  }) {
    return protected ?? false
        ? ProtectedTextField(ProtectedData.fromString(text))
        : PlainTextField(text);
  }

  /// Clones a [KdbxTextField] from [other].
  factory KdbxTextField.copyFrom(KdbxTextField other) => KdbxTextField.fromText(
        text: other.text,
        protected: other is ProtectedTextField,
      );

  /// Constructs a [KdbxTextField] from the xml [element].
  /// The [header] is used to access salt generator for ptotected fields.
  factory KdbxTextField.fromXml({
    required XmlElement element,
    required KdbxHeader header,
  }) {
    if (XmlUtils.getBooleanAttribute(element, XmlAttr.protected)) {
      final bytes = base64.decode(element.innerText);
      return ProtectedTextField(
        ProtectedData.fromProtectedBytes(
          bytes: bytes,
          salt: header.saltGenerator.getSalt(bytes.length),
        ),
      );
    }

    if (XmlUtils.getBooleanAttribute(element, XmlAttr.protectedInMemory)) {
      return ProtectedTextField(ProtectedData.fromString(element.innerText));
    }

    return PlainTextField(element.innerText);
  }

  /// Serializes the text field to an XML element.
  XmlElement toXml({
    required KdbxHeader header,
    required bool protectValues,
  }) {
    final element = XmlElement(XmlName(XmlElem.value));
    final field = this;

    if (field is PlainTextField) {
      element.innerText = field.text;
    } else if (field is ProtectedTextField) {
      if (protectValues) {
        element.setAttribute(XmlAttr.protected, 'True');
        var data = field.protectedText.bytes;
        data = CryptoUtils.transformXor(
          data: data,
          salt: header.saltGenerator.getSalt(data.length),
        );
        element.innerText = base64.encode(data);
      } else {
        element.setAttribute(XmlAttr.protectedInMemory, 'True');
        element.innerText = field.protectedText.text;
      }
    }

    return element;
  }

  /// The value of the text field.
  String get text;
}

/// Represents plain text field
class PlainTextField extends KdbxTextField {
  @override
  String text;

  /// Constructs a [PlainTextField] from provided [text].
  PlainTextField(this.text) : super._();
}

/// Represents encrypted text field
class ProtectedTextField extends KdbxTextField {
  /// The protected value of the field.
  ProtectedData protectedText;

  /// Constructs a [ProtectedTextField] from provided [protectedText].
  ProtectedTextField(this.protectedText) : super._();

  @override
  String get text => protectedText.text;
}

/// Edit state of a KDBX entry.
class KdbxEntryEditState {
  final _added = <KdbxTime>[];
  final _deleted = <KdbxTime>[];

  /// Constructs an empty [KdbxEntryEditState].
  KdbxEntryEditState.empty();

  /// Constructs a [KdbxEntryEditState] from XML [node].
  factory KdbxEntryEditState.fromXml(XmlNode node) {
    final state = KdbxEntryEditState.empty();

    for (var e in node.childElements) {
      final time = KdbxTime.fromXmlText(
        text: e.innerText,
        isBinary: true,
      );
      switch (e.qualifiedName) {
        case XmlElem.added:
          state._added.add(time);
        case XmlElem.deleted:
          state._deleted.add(time);
      }
    }

    return state;
  }

  /// Serializes the state to an XML node.
  XmlNode toXml() {
    return XmlUtils.createElement(
      name: XmlElem.entryEditState,
      children: [
        ..._added.map((e) => (XmlElem.added, e)),
        ..._deleted.map((e) => (XmlElem.deleted, e)),
      ],
      binaryTime: true,
    );
  }
}

/// Represents KDBX entry structure
class KdbxEntry extends KdbxItem {
  /// The autotype.
  var autoType = KdbxAutoType();

  /// The entry foreground color.
  String? foreground;

  /// The entry background color.
  String? background;

  /// The override URL field.
  String? overrideUrl;

  /// The entry custom fields.
  Map<String, KdbxTextField> fields = {};

  /// The entry binaries.
  Map<String, BinaryReference> binaries = {};

  /// The history values of the entry.
  List<KdbxEntry> history = [];

  /// The quality check flag.
  bool? qualityCheck;

  ///The edit state of the entry.
  var editState = KdbxEntryEditState.empty();

  KdbxEntry._(super.id);

  /// Constructs a [KdbxEntry] in the [parent] group.
  factory KdbxEntry.create({
    required KdbxGroup parent,
    required KdbxMeta meta,
    required KdbxUuid id,
  }) {
    final entry = KdbxEntry._(id);
    entry.icon = KdbxIcon.key;
    entry.times = KdbxTimes();
    entry.parent = parent;

    entry.fields.addAll({
      'Title': KdbxTextField.fromText(
          text: '', protected: meta.memoryProtection.title),
      'UserName': KdbxTextField.fromText(
          text: meta.defaultUser ?? '',
          protected: meta.memoryProtection.userName),
      'Password': KdbxTextField.fromText(
          text: '', protected: meta.memoryProtection.password),
      'URL': KdbxTextField.fromText(
          text: '', protected: meta.memoryProtection.url),
      'Notes': KdbxTextField.fromText(
          text: '', protected: meta.memoryProtection.notes),
    });

    entry.autoType.enabled = parent.isAutoTypeEnabled ?? false;
    entry.autoType.obfuscation = AutoTypeObfuscationOptions.none;
    return entry;
  }

  ///Clones a [KdbxEntry] from [other].
  factory KdbxEntry.copyFrom(KdbxEntry other, KdbxUuid id) =>
      KdbxEntry._(id).._copyFrom(other);

  ///Constructs a [KdbxEntry] from the XML [node].
  factory KdbxEntry.fromXml({
    required XmlElement node,
    required KdbxHeader header,
    required bool binaryTime,
    KdbxGroup? parent,
  }) {
    final entry = KdbxEntry._(KdbxUuid.zero);

    for (var element in node.childElements) {
      if (element.qualifiedName.isNotEmpty) {
        entry._readNode(element, header, binaryTime);
      }
    }

    entry.parent = parent;
    return entry;
  }

  @override
  XmlNode toXml({
    required KdbxHeader header,
    required bool exportXml,
    required bool binaryTime,
    required bool includeHistory, // TODO: replace with HistoryEntry type
  }) {
    final is41 = header.versionIsAtLeast(4, 1);
    final node = XmlUtils.createElement(name: XmlElem.entry, children: [
      (XmlElem.fgColor, foreground),
      (XmlElem.bgColor, background),
      (XmlElem.overrideUrl, overrideUrl),
      if (is41) (XmlElem.qualityCheck, qualityCheck),
    ]);

    super.appendToXml(
      node: node,
      is41: is41,
      binaryTime: binaryTime,
    );

    final fieldsNodes = fields.entries.map((e) {
      return XmlElement(
        XmlName(XmlElem.string),
        [],
        [
          XmlElement(XmlName(XmlElem.key))..innerText = e.key,
          e.value.toXml(header: header, protectValues: !exportXml),
        ],
      );
    });

    final binariesNodes = binaries.entries.map(
      (e) => e.value.toXml(e.key),
    );

    getHistory() => XmlElement(
          XmlName(XmlElem.history),
          [],
          history.map(
            (e) => e.toXml(
              header: header,
              exportXml: exportXml,
              binaryTime: binaryTime,
              includeHistory: false,
            ),
          ),
        );

    node.children.addAll(
      [
        ...fieldsNodes,
        ...binariesNodes,
        if (includeHistory) getHistory(),
        autoType.toXml(),
      ],
    );

    return node;
  }

  /// Inserts the current entry state to the history.
  pushHistory() {
    final historyEntry = KdbxEntry.copyFrom(this, uuid);
    history.add(historyEntry);
    _addHistoryTombstone(
      _EditAction.added,
      historyEntry.times.modification,
    );
  }

  ///Removes the history records from [start] to [end].
  ///If end is null – removes a single record.
  removeFromHistory({required int start, int? end}) {
    end ??= start + 1;

    for (var ix = start; ix < end; ix++) {
      if (ix < history.length) {
        _addHistoryTombstone(
          _EditAction.deleted,
          history[ix].times.modification,
        );
      }
    }

    history.removeRange(start, end);
  }

  @override
  merge(MergeObjectMap objectMap) {
    final remote = objectMap.remoteItems[uuid];

    if (remote is! KdbxEntry) {
      return;
    }

    if (remote.times.modification.isAfter(times.modification)) {
      pushHistory();
      _copyFrom(remote);
    }

    history = _mergeHistory(remote);
  }

  /// Merges [remote] entry history to this entry history.
  /// Tombstones are stored locally and must be immediately discarded by replica after successful upstream push.
  /// It's client responsibility, to save and load tombstones for local replica, and to clear them after successful upstream push.
  ///
  /// Format doesn't allow saving tombstones for history entries, so they are stored locally.
  /// Any unmodified state from past or modifications of current state synced with central upstream will be successfully merged.
  /// Assumes there's only one central upstream, may produce inconsistencies while merging outdated replica outside main upstream.
  /// Phantom entries and phantom deletions will appear if remote replica checked out an old state and has just added a new state.
  /// If a client is using central upstream for sync, the remote replica must first sync it state and
  /// only after it update the upstream, so this should never happen.
  ///
  /// References:
  ///
  /// An Optimized Conflict-free Replicated Set arXiv:1210.3368
  /// http://arxiv.org/abs/1210.3368
  ///
  /// Gene T. J. Wuu and Arthur J. Bernstein. Efficient solutions to the replicated log and dictionary
  /// problems. In Symp. on Principles of Dist. Comp. (PODC), pages 233–242, Vancouver, BC, Canada, August 1984.
  /// https://pages.lip6.fr/Marc.Shapiro/papers/RR-7687.pdf
  List<KdbxEntry> _mergeHistory(KdbxEntry remote) {
    final remoteMap = Map.fromEntries(
      [
        ...remote.history,
        if (times.modification.isAfter(remote.times.modification)) remote,
      ].map((e) => MapEntry(e.times.modification, e)),
    );

    final mergedMap = SplayTreeMap<KdbxTime, KdbxEntry>.fromIterable(
      history.where((e) {
        final mt = e.times.modification;
        return remoteMap.containsKey(mt) ||
            editState._added.contains(mt) ||
            mt.isAfter(remote.times.modification);
      }),
      key: (e) => e.times.modification,
      compare: (a, b) => a.compareTo(b),
    );

    mergedMap.addEntries(
      remoteMap.entries
          .where((re) =>
              !mergedMap.containsKey(re.key) &&
              !editState._deleted.contains(re.key))
          .map(
            (re) => MapEntry(
              re.key,
              KdbxEntry.copyFrom(re.value, uuid),
            ),
          ),
    );

    return mergedMap.values.toList();
  }

  _copyFrom(KdbxEntry other) {
    icon = other.icon;
    customIcon = other.customIcon;
    foreground = other.foreground;
    background = other.background;
    overrideUrl = other.overrideUrl;

    final tags = other.tags;
    this.tags = tags == null ? null : List.from(tags);
    times = KdbxTimes.copyFrom(other.times);

    fields = other.fields
        .map((key, value) => MapEntry(key, KdbxTextField.copyFrom(value)));
    binaries = other.binaries
        .map((key, value) => MapEntry(key, BinaryReference(value.id)));

    autoType = KdbxAutoType.copyFrom(other.autoType);
  }

  _addHistoryTombstone(_EditAction action, KdbxTime dt) => (switch (action) {
        _EditAction.added => editState._added,
        _EditAction.deleted => editState._deleted,
      })
          .add(dt);

  _readNode(XmlElement node, KdbxHeader header, bool binaryTime) {
    switch (node.qualifiedName) {
      case XmlElem.uuid:
        uuid = KdbxUuid.fromString(node.innerText);
      case XmlElem.icon:
        icon = KdbxIcon.fromInt(int.tryParse(node.innerText) ?? 0);
      case XmlElem.customIconID:
        customIcon = KdbxUuid.fromString(node.innerText);
      case XmlElem.fgColor:
        foreground = node.innerText;
      case XmlElem.bgColor:
        background = node.innerText;
      case XmlElem.overrideUrl:
        overrideUrl = node.innerText;
      case XmlElem.tags:
        tags = XmlUtils.getTags(node);
      case XmlElem.times:
        times = KdbxTimes.fromXml(node: node, isBinary: binaryTime);
      case XmlElem.string:
        _readField(node, header);
      case XmlElem.binary:
        _readBinary(node, header);
      case XmlElem.autoType:
        autoType = KdbxAutoType.fromXml(node);
      case XmlElem.history:
        _readHistory(node, header, binaryTime);
      case XmlElem.customData:
        customData = KdbxCustomData.fromXml(node);
      case XmlElem.qualityCheck:
        qualityCheck = XmlUtils.getBoolean(node);
      case XmlElem.previousParentGroup:
        previousParent = KdbxUuid.fromString(node.innerText);
    }
  }

  _readField(XmlElement node, KdbxHeader header) {
    String? key;
    KdbxTextField? value;

    for (var element in node.childElements) {
      switch (element.qualifiedName) {
        case XmlElem.key:
          key = element.innerText;
        case XmlElem.value:
          value = KdbxTextField.fromXml(
            element: element,
            header: header,
          );
      }
    }

    if (key != null) {
      fields[key] = value ?? PlainTextField('');
    }
  }

  _readBinary(XmlElement element, KdbxHeader header) {
    String? key;
    BinaryReference? value;

    for (final e in element.childElements) {
      switch (e.qualifiedName) {
        case XmlElem.key:
          key = e.innerText;
        case XmlElem.value:
          var binary = KdbxBinary.fromXml(element: e, header: header);
          if (binary is KdbxDataBinary) {
            binary = header.binaries.add(binary);
          }
          if (binary is! BinaryReference) {
            throw FileCorruptedError('wrong binary type in entry structure');
          }
          value = binary;
      }
    }

    if (key != null && value != null) {
      binaries[key] = value;
    }
  }

  _readHistory(XmlElement node, KdbxHeader header, bool binaryTime) =>
      history.addAll(node.childElements
          .where((e) => e.qualifiedName == XmlElem.entry)
          .map((e) => KdbxEntry.fromXml(
                node: e,
                header: header,
                binaryTime: binaryTime,
              )));
}

enum _EditAction { added, deleted }
