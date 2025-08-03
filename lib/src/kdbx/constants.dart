// ignore_for_file: public_member_api_docs

/// Standard icons.
enum KdbxIcon {
  key(0),
  world(1),
  warning(2),
  networkServer(3),
  markedDirectory(4),
  userCommunication(5),
  parts(6),
  notepad(7),
  worldSocket(8),
  identity(9),
  paperReady(10),
  digicam(11),
  irCommunication(12),
  multiKeys(13),
  energy(14),
  scanner(15),
  worldStar(16),
  cdRom(17),
  monitor(18),
  eMail(19),
  configuration(20),
  clipboardReady(21),
  paperNew(22),
  screen(23),
  energyCareful(24),
  eMailBox(25),
  disk(26),
  drive(27),
  paperQ(28),
  terminalEncrypted(29),
  console(30),
  printer(31),
  programIcons(32),
  run(33),
  settings(34),
  worldComputer(35),
  archive(36),
  homebanking(37),
  driveWindows(38),
  clock(39),
  eMailSearch(40),
  paperFlag(41),
  memory(42),
  trashBin(43),
  note(44),
  expired(45),
  info(46),
  package(47),
  folder(48),
  folderOpen(49),
  folderPackage(50),
  lockOpen(51),
  paperLocked(52),
  checked(53),
  pen(54),
  thumbnail(55),
  book(56),
  list(57),
  userKey(58),
  tool(59),
  home(60),
  star(61),
  tux(62),
  feather(63),
  apple(64),
  wiki(65),
  money(66),
  certificate(67),
  blackBerry(68);

  const KdbxIcon(this.value);
  final int value;

  factory KdbxIcon.fromInt(int value) => values.elementAtOrNull(value) ?? key;
}

/// A compression type.
enum CompressionAlgorithm {
  none,
  gzip;
}

/// A CRC algorithm.
enum CrsAlgorithm {
  none(0),
  arcFourVariant(1),
  salsa20(2),
  chaCha20(3);

  const CrsAlgorithm(this.value);

  factory CrsAlgorithm.fromValue(int value) =>
      values.elementAtOrNull(value) ?? none;

  final int value;
}

/// Type of argon algorithm.
enum Argon2Type {
  argon2d(0),
  argon2id(2);

  const Argon2Type(this.value);

  final int value;
}

/// Various default constants.
abstract final class Defaults {
  static const recycleBinName = 'Recycle Bin';
  static const keyEncryptionRounds = 300000;
  static const generator = 'KPassLib';
  static const historyMaxItems = 10;
  static const historyMaxSize = 6 * DataSize.mebi;
}

/// A data magnitude order.
abstract final class DataSize {
  static const kibi = 1 << 10;
  static const mebi = kibi << 10;
}

/// Identifier of KDF.
abstract final class KdfId {
  static const argon2d = '72Nt34wpREuR96mkA+MKDA==';
  static const argon2id = 'nimLGVbbR3OyPfw+xvCh5g==';
  static const aes = 'ydnzmmKKRGC/dA0IwYpP6g==';
}

/// A cipher identifier.
abstract final class CipherId {
  static const aes = 'McHy5r9xQ1C+WAUhavxa/w==';
  static const chaCha20 = '1gOKK4tvTLWlJDOaMdu1mg==';
}

/// Signature constants.
abstract final class Signatures {
  static const fileMagic = 0x9aa2d903;
  static const sig2Kdbx = 0xb54bfb67;
}

/// KDBX XML elements names.
abstract final class XmlElem {
  static const docNode = 'KeePassFile';

  static const meta = 'Meta';
  static const root = 'Root';
  static const group = 'Group';
  static const entry = 'Entry';

  static const generator = 'Generator';
  static const headerHash = 'HeaderHash';
  static const settingsChanged = 'SettingsChanged';
  static const dbName = 'DatabaseName';
  static const dbNameChanged = 'DatabaseNameChanged';
  static const dbDesc = 'DatabaseDescription';
  static const dbDescChanged = 'DatabaseDescriptionChanged';
  static const dbDefaultUser = 'DefaultUserName';
  static const dbDefaultUserChanged = 'DefaultUserNameChanged';
  static const dbMaintenanceHistoryDays = 'MaintenanceHistoryDays';
  static const dbColor = 'Color';
  static const dbKeyChanged = 'MasterKeyChanged';
  static const dbKeyChangeRec = 'MasterKeyChangeRec';
  static const dbKeyChangeForce = 'MasterKeyChangeForce';
  static const recycleBinEnabled = 'RecycleBinEnabled';
  static const recycleBinUuid = 'RecycleBinUUID';
  static const recycleBinChanged = 'RecycleBinChanged';
  static const entryTemplatesGroup = 'EntryTemplatesGroup';
  static const entryTemplatesGroupChanged = 'EntryTemplatesGroupChanged';
  static const historyMaxItems = 'HistoryMaxItems';
  static const historyMaxSize = 'HistoryMaxSize';
  static const lastSelectedGroup = 'LastSelectedGroup';
  static const lastTopVisibleGroup = 'LastTopVisibleGroup';

  static const memoryProtection = 'MemoryProtection';
  static const protTitle = 'ProtectTitle';
  static const protUserName = 'ProtectUserName';
  static const protPassword = 'ProtectPassword';
  static const protUrl = 'ProtectURL';
  static const protNotes = 'ProtectNotes';

  static const customIcons = 'CustomIcons';
  static const customIconItem = 'Icon';
  static const customIconItemID = 'UUID';
  static const customIconItemData = 'Data';
  static const customIconItemName = 'Name';

  static const autoType = 'AutoType';
  static const history = 'History';

  static const name = 'Name';
  static const notes = 'Notes';
  static const uuid = 'UUID';
  static const icon = 'IconID';
  static const customIconID = 'CustomIconUUID';
  static const fgColor = 'ForegroundColor';
  static const bgColor = 'BackgroundColor';
  static const overrideUrl = 'OverrideURL';
  static const times = 'Times';
  static const tags = 'Tags';
  static const qualityCheck = 'QualityCheck';
  static const previousParentGroup = 'PreviousParentGroup';

  static const creationTime = 'CreationTime';
  static const lastModTime = 'LastModificationTime';
  static const lastAccessTime = 'LastAccessTime';
  static const expiryTime = 'ExpiryTime';
  static const expires = 'Expires';
  static const usageCount = 'UsageCount';
  static const locationChanged = 'LocationChanged';

  static const groupDefaultAutoTypeSeq = 'DefaultAutoTypeSequence';
  static const groupEnableAutoType = 'EnableAutoType';
  static const enableSearching = 'EnableSearching';

  static const string = 'String';
  static const binary = 'Binary';
  static const key = 'Key';
  static const value = 'Value';

  static const autoTypeEnabled = 'Enabled';
  static const autoTypeObfuscation = 'DataTransferObfuscation';
  static const autoTypeDefaultSequence = 'DefaultSequence';
  static const autoTypeItem = 'Association';
  static const window = 'Window';
  static const keystrokeSequence = 'KeystrokeSequence';

  static const binaries = 'Binaries';

  static const isExpanded = 'IsExpanded';
  static const lastTopVisibleEntry = 'LastTopVisibleEntry';

  static const deletedObjects = 'DeletedObjects';
  static const deletedObject = 'DeletedObject';
  static const deletionTime = 'DeletionTime';

  static const customData = 'CustomData';
  static const stringDictExItem = 'Item';
  static const version = 'Version';
  static const data = 'Data';

  static const metaEditState = 'MetaEditState';
  static const maintenanceHistoryDaysChanged = 'MaintenanceHistoryDaysChanged';
  static const colorChanged = 'ColorChanged';
  static const keyChangeRecChanged = 'KeyChangeRecChanged';
  static const keyChangeForceChanged = 'KeyChangeForceChanged';
  static const historyMaxItemsChanged = 'HistoryMaxItemsChanged';
  static const historyMaxSizeChanged = 'HistoryMaxSizeChanged';
  static const lastSelectedGroupChanged = 'LastSelectedGroupChanged';
  static const lastTopVisibleGroupChanged = 'LastTopVisibleGroupChanged';
  static const memoryProtectionChanged = 'MemoryProtectionChanged';

  static const entryEditState = 'EntryEditState';
  static const added = 'Added';
  static const deleted = 'Deleted';

  static const kdbxEditState = 'KdbxEditState';
  static const entries = 'Entries';
}

/// KDBX XML elements attributes.
abstract final class XmlAttr {
  static const id = 'ID';
  static const ref = 'Ref';
  static const protected = 'Protected';
  static const protectedInMemory = 'ProtectInMemory';
  static const compressed = 'Compressed';
  static const hash = 'Hash';
}
