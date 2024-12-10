import 'package:kpasslib/src/kdbx/kdbx_custom_data.dart';
import 'package:kpasslib/src/utils/xml_utils.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('Custom data unit tests', () {
    test('reads custom data from xml', () {
      final xml = XmlDocument.parse('<CustomData>'
          '<Item><Key>k1</Key><Value>v1</Value></Item>'
          '<Item><Key>k2</Key><Value>v2</Value></Item>'
          '</CustomData>');
      final cd = KdbxCustomData.fromXml(xml.firstChild!);
      expect(cd.map, {
        'k1': KdbxCustomItem(value: 'v1'),
        'k2': KdbxCustomItem(value: 'v2')
      });
    });

    test('reads empty custom data from empty xml', () {
      final xml = XmlDocument.parse('<CustomData></CustomData>');
      final cd = KdbxCustomData.fromXml(xml.firstChild!);
      expect(cd.map.isEmpty, true);
    });

    test('skips unknown tags', () {
      final xml = XmlDocument.parse(
          '<CustomData><Item><Key>k</Key><Value>v</Value><x></x></Item><Something></Something></CustomData>');
      final cd = KdbxCustomData.fromXml(xml.firstChild!);
      expect(cd.map, {'k': KdbxCustomItem(value: 'v')});
    });

    test('skips absent keys', () {
      final xml = XmlDocument.parse(
          '<CustomData><Item><Value>v</Value></Item></CustomData>');
      final cd = KdbxCustomData.fromXml(xml.firstChild!);
      expect(cd.map.isEmpty, true);
    });

    test('writes custom data to xml', () {
      final cd = KdbxCustomData();
      cd.map = {
        'k1': KdbxCustomItem(value: 'v1'),
        'k2': KdbxCustomItem(value: 'v2')
      };
      final xml = XmlUtils.create('root');
      xml.firstElementChild?.children
          .add(cd.toXml(includeModificationTime: false)!);
      expect(
          xml.lastChild?.toXmlString(),
          '<root><CustomData>'
          '<Item><Key>k1</Key><Value>v1</Value></Item>'
          '<Item><Key>k2</Key><Value>v2</Value></Item>'
          '</CustomData></root>');
    });

    test('writes no custom data to xml', () {
      final cd = KdbxCustomData();
      expect(cd.toXml(includeModificationTime: false), null);
    });
  });
}
