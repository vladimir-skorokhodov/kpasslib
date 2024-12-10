import 'package:kpasslib/kpasslib.dart';
import 'package:kpasslib/src/utils/xml_utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('XML utils unit tests', () {
    test('creates XML document', () {
      final doc = XmlUtils.create('root');
      expect(doc.rootElement.qualifiedName, 'root');
    });

    test('gets first child node', () {
      final xml =
          XmlDocument.parse('<root><item>1</item><item>2</item></root>');
      final childNode = XmlUtils.getChildNodeOrNull(xml.rootElement, 'item');
      expect(childNode?.innerText, '1');
    });

    test("gets null if there's no matching child node", () {
      final xml =
          XmlDocument.parse('<root><item>1</item><item>2</item></root>');
      final childNode =
          XmlUtils.getChildNodeOrNull(xml.rootElement, 'notexisting');
      expect(childNode, null);
    });

    test("gets null if there's no child nodes at all", () {
      final xml = XmlDocument.parse('<root><item/></root>');
      var childNode = XmlUtils.getChildNodeOrNull(xml.rootElement, 'item');
      expect(childNode != null, true);
      childNode = XmlUtils.getChildNodeOrNull(
        childNode as XmlElement,
        'notexisting',
      );
      expect(childNode, null);
    });

    test("throws error if there's no matching node", () {
      final xml = XmlDocument.parse('<root><item/></root>');
      expect(
        () => XmlUtils.getChildNode(
          xml.rootElement,
          'notexisting',
          'not found',
        ),
        throwsA(
          predicate(
            (e) => e is FileCorruptedError && e.message.contains('not found'),
          ),
        ),
      );
    });

    test('adds child node', () {
      final xml = XmlDocument.parse('<root><old/></root>');
      XmlUtils.addChildren(parent: xml.firstChild!, children: [('item', '')]);
      XmlUtils.addChildren(
          parent: xml.firstChild!.lastChild!, children: [('inner', '')]);
      expect(xml.toXmlString(), '<root><old/><item><inner/></item></root>');
    });

    test('returns node tags', () {
      final xml = XmlDocument.parse(
          '<item>Tag1 ; Tag2, Another tag  , more tags </item>');
      final tags = XmlUtils.getTags(xml.rootElement);
      expect(tags, ['Tag1', 'Tag2', 'Another tag', 'more tags']);
    });

    test('returns empty tags for an empty node', () {
      final xml = XmlDocument.parse('<item></item>');
      final tags = XmlUtils.getTags(xml.rootElement);
      expect(tags, []);
    });

    test('returns empty tags for a closed node', () {
      final xml = XmlDocument.parse('<item />');
      final tags = XmlUtils.getTags(xml.rootElement);
      expect(tags, []);
    });

    test('returns empty tags for a node with blank text', () {
      final xml = XmlDocument.parse('<item>   </item>');
      final tags = XmlUtils.getTags(xml.rootElement);
      expect(tags, []);
    });

    test('sets node date in ISO format', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(
          parent: xml.firstChild!,
          children: [('item', KdbxTime(DateTime.utc(2015, 8, 17, 21, 20)))]);
      expect(xml.toXmlString(),
          '<root><item>2015-08-17T21:20:00.000Z</item></root>');
    });

    test('sets node date in binary format', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(
          parent: xml.firstChild!,
          children: [('item', KdbxTime(DateTime.utc(2015, 8, 16, 14, 45, 23)))],
          binaryTime: true);
      expect(xml.toXmlString(), '<root><item>A5lizQ4AAAA=</item></root>');
    });

    test('sets node empty date', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(
          parent: xml.firstChild!,
          children: [('item', null)],
          binaryTime: true);
      expect(xml.toXmlString(), '<root/>');
    });

    test('returns node date', () {
      final xml = XmlDocument.parse('<item>2015-01-02T03:04:05Z</item>');
      final dt = KdbxTime.fromXmlText(
          text: xml.firstChild!.innerText, isBinary: false);
      expect(dt.time, DateTime.utc(2015, 1, 2, 3, 4, 5));
    });

    test('returns node date from base64', () {
      final xml = XmlDocument.parse('<item>A5lizQ4AAAA=</item>');
      final dt =
          KdbxTime.fromXmlText(text: xml.firstChild!.innerText, isBinary: true);
      expect(dt.time, DateTime.utc(2015, 8, 16, 14, 45, 23));
    });

    test('returns undefined for empty node', () {
      final xml = XmlDocument.parse('<item></item>');
      final dt = KdbxTime.fromXmlText(
          text: xml.firstChild!.innerText, isBinary: false);
      expect(dt.time, null);
    });

    test('returns node true', () {
      var xml = XmlDocument.parse('<item>True</item>');
      var bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, true);
      xml = XmlDocument.parse('<item>true</item>');
      bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, true);
    });

    test('returns node false', () {
      var xml = XmlDocument.parse('<item>False</item>');
      var bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, false);
      xml = XmlDocument.parse('<item>false</item>');
      bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, false);
    });

    test('returns null for unknown text', () {
      final xml = XmlDocument.parse('<item>blablabla</item>');
      final bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, null);
    });

    test('returns null for null', () {
      final xml = XmlDocument.parse('<item>null</item>');
      final bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, null);
    });

    test('returns null for empty node', () {
      final xml = XmlDocument.parse('<item></item>');
      final bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, null);
    });

    test('returns null for closed node', () {
      final xml = XmlDocument.parse('<item />');
      final bool = XmlUtils.getBoolean(xml.firstElementChild);
      expect(bool, null);
    });

    test('sets node false', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(
          parent: xml.firstChild!, children: [('item', false)]);
      expect(xml.toXmlString(), '<root><item>False</item></root>');
    });

    test('sets node true', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(parent: xml.firstChild!, children: [('item', true)]);
      expect(xml.toXmlString(), '<root><item>True</item></root>');
    });

    test('sets node null', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(parent: xml.firstChild!, children: [('item', null)]);
      expect(xml.toXmlString(), '<root/>');
    });

    test('sets node uuid', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(
          parent: xml.firstChild!,
          children: [('item', KdbxUuid.fromBytes(List<int>.filled(16, 0)))]);
      expect(xml.toXmlString(),
          '<root><item>AAAAAAAAAAAAAAAAAAAAAA==</item></root>');
    });

    test('sets node empty uuid', () {
      final xml = XmlDocument.parse('<root/>');
      XmlUtils.addChildren(parent: xml.firstChild!, children: [('item', null)]);
      expect(xml.toXmlString(), '<root/>');
    });
  });
}
