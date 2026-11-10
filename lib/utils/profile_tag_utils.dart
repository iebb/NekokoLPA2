import 'package:intl/intl.dart';
import 'package:dlibphonenumber/dlibphonenumber.dart';
import '../settings/app_settings.dart';

class ProfileTagUtils {
  static const String tagSeparator = '\x0A';
  static const String internalSpace = '\x11';
  static const String internalColon = '\x03';

  static String escapeContent(String s) {
    return s.replaceAll(' ', internalSpace).replaceAll(':', internalColon);
  }

  static String unescapeContent(String s) {
    return s.replaceAll(internalSpace, ' ').replaceAll(internalColon, ':');
  }

  // Word boundary \b so a tag is not matched inside a word: " d:..." or a
  // leading "d:...". [td] is the tag kind, [\S\x11]+ its content.
  static final RegExp _tagPattern = RegExp(
    r'\b([td]:[\S\x11]+)',
    caseSensitive: false,
  );
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _nonPhoneChars = RegExp(r'[^\d\+\s\.\-\(\)]');

  /// The tags in a nickname, without the name clean-up and phone-number
  /// formatting [parse] also does.
  static List<ProfileTag> parseTags(String? fullNickname) {
    if (fullNickname == null || fullNickname.isEmpty) return [];
    return [
      for (final m in _tagPattern.allMatches(fullNickname))
        ProfileTag.parse(m.group(1)!),
    ];
  }

  // Parses nickname string, handling standard and legacy (space-separated) formats.
  static ParsedNickname parse(String? fullNickname, {String? regionCode}) {
    if (fullNickname == null || fullNickname.isEmpty) {
      return ParsedNickname('', []);
    }

    final tags = parseTags(fullNickname);

    String name = fullNickname
        .replaceAll(_tagPattern, '')
        .replaceAll(tagSeparator, '')
        .trim();
    // Collapse multiple spaces if any were left by removing tags
    name = name.replaceAll(_whitespace, ' ');

    String displayName = name;
    final String region = (regionCode == null || regionCode == "UN")
        ? "US"
        : regionCode;

    try {
      final phoneNumberUtil = PhoneNumberUtil.instance;
      // Clean string for findNumbers (replace non-phone chars with spaces to allow detection near words)
      final cleanedText = name.replaceAll(_nonPhoneChars, ' ');

      final strategy = AppSettings().phoneFormatStrategy;

      if (strategy != PhoneFormatStrategy.off) {
        final list = phoneNumberUtil.findNumbers(cleanedText, region).toList();
        // Sort backwards to replace without index shifting issues
        list.sort((a, b) => b.start.compareTo(a.start));

        for (final m in list) {
          final type = phoneNumberUtil.getNumberType(m.number);
          final isMobile =
              type == PhoneNumberType.mobile ||
              type == PhoneNumberType.fixedLineOrMobile;
          final hasPlus = m.rawString.contains('+');

          bool shouldFormat = false;
          switch (strategy) {
            case PhoneFormatStrategy.internationalOnly:
              shouldFormat = hasPlus;
              break;
            case PhoneFormatStrategy.internationalAndMobile:
              shouldFormat = hasPlus || isMobile;
              break;
            case PhoneFormatStrategy.internationalAndAll:
              shouldFormat = true; // Format any valid number found
              break;
            case PhoneFormatStrategy.off:
              shouldFormat = false;
              break;
          }

          if (shouldFormat) {
            final formatted = phoneNumberUtil.format(
              m.number,
              PhoneNumberFormat.international,
            );
            displayName = displayName.replaceRange(m.start, m.end, formatted);
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors, keep original name as displayName
    }

    return ParsedNickname(name, tags, displayName: displayName);
  }

  static String format(String name, List<ProfileTag> tags) {
    if (tags.isEmpty) return name;
    final joinedTags = tags.map((t) => t.raw).join(' ');
    final result = '$name$tagSeparator$joinedTags';
    return result;
  }
}

class ProfileTag {
  final String raw;
  ProfileTag(this.raw);

  static ProfileTag parse(String tag) {
    // tag identifier is case insensitive for detection, but we keep content as is?
    // Actually standard is 'd:' and 't:'.
    if (tag.toLowerCase().startsWith('d:')) {
      return DateTag.parse(tag);
    } else if (tag.toLowerCase().startsWith('t:')) {
      return TextTag.parse(tag);
    }
    return TextTag.parse('t:$tag'); // Fallback
  }

  String get id => raw;
}

class TextTag extends ProfileTag {
  final String text;

  TextTag(this.text) : super('t:${ProfileTagUtils.escapeContent(text)}');

  static TextTag parse(String raw) {
    final content = raw.substring(2);
    return TextTag(ProfileTagUtils.unescapeContent(content));
  }
}

class DateTag extends ProfileTag {
  final DateTime date;
  final String? note;

  DateTag(this.date, [this.note])
    : super(
        'd:${DateFormat('yyMMdd').format(date)}${note != null ? ':${ProfileTagUtils.escapeContent(note)}' : ''}',
      );

  static DateTag parse(String raw) {
    final parts = raw.split(':');
    // d:YYMMDD:NOTE -> parts[0]=d, parts[1]=date, parts[2...]=note
    if (parts.length < 2) return DateTag(DateTime.now());

    var dateStr = parts[1].trim();

    DateTime date;
    try {
      // Compatibility: Support YYYYMMDD (8 digits)
      if (dateStr.length >= 8) {
        final clean = dateStr.substring(0, 8);
        // Check if actually digits
        if (int.tryParse(clean) != null) {
          final y = int.parse(clean.substring(0, 4));
          final m = int.parse(clean.substring(4, 6));
          final d = int.parse(clean.substring(6, 8));
          date = DateTime(y, m, d);
        } else {
          // Try strict parsing via intl just in case
          date = DateFormat('yyyyMMdd').parseLoose(clean);
        }
      } else {
        // Standard: YYMMDD (6 digits)
        final clean = dateStr.length > 6 ? dateStr.substring(0, 6) : dateStr;
        if (clean.length == 6 && int.tryParse(clean) != null) {
          final y = int.parse(clean.substring(0, 2));
          final m = int.parse(clean.substring(2, 4));
          final d = int.parse(clean.substring(4, 6));
          date = DateTime(2000 + y, m, d);
        } else {
          date = DateFormat('yyMMdd').parse(clean);
        }
      }

      if (date.year < 2000) {
        date = DateTime(date.year + 100, date.month, date.day);
      }
    } catch (e) {
      date = DateTime.now();
    }

    String? note;
    if (parts.length > 2) {
      // Re-join just in case
      note = ProfileTagUtils.unescapeContent(parts.sublist(2).join(':'));
    }

    return DateTag(date, note);
  }

  String get displayDate => DateFormat('yyyy-MM-dd').format(date);

  Duration get countdown {
    final now = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(now);
  }
}

class ParsedNickname {
  final String name;
  final List<ProfileTag> tags;
  final String displayName;

  ParsedNickname(this.name, this.tags, {String? displayName})
    : displayName = displayName ?? name;
}
