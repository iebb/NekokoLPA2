import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/utils/profile_tag_utils.dart';

void main() {
  const nicknames = [
    '',
    'Travel',
    'Travel t:work',
    't:work Travel d:261231',
    'Japan d:261231:renew${ProfileTagUtils.internalSpace}soon t:data',
    'T:Upper D:260101',
    'not:atag mid:word',
    'Line${ProfileTagUtils.tagSeparator}t:two',
  ];

  test('parseTags finds the same tags as parse', () {
    for (final nickname in nicknames) {
      expect(
        ProfileTagUtils.parseTags(nickname).map((t) => t.raw).toList(),
        ProfileTagUtils.parse(nickname).tags.map((t) => t.raw).toList(),
        reason: nickname,
      );
    }
  });

  test('parseTags returns nothing for a missing nickname', () {
    expect(ProfileTagUtils.parseTags(null), isEmpty);
    expect(ProfileTagUtils.parseTags(''), isEmpty);
  });

  test('parse strips tags from the name and keeps their order', () {
    final parsed = ProfileTagUtils.parse('t:work Travel d:261231');
    expect(parsed.name, 'Travel');
    expect(parsed.tags.map((t) => t.raw), ['t:work', 'd:261231']);
    expect(parsed.tags.first, isA<TextTag>());
    expect(parsed.tags.last, isA<DateTag>());
  });

  test('a tag marker inside a word is not a tag', () {
    expect(ProfileTagUtils.parseTags('budget:plan'), isEmpty);
  });
}
