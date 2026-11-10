import '../models/euicc_profile.dart';
import '../services/profile_metadata_service.dart';
import '../settings/app_settings.dart';
import 'mcc_mapper.dart';

class ProfileRedaction {
  static const String _mask = '*';
  static final RegExp _phoneNumber = RegExp(r'(\+?\d[\d\s().-]{5,}\d)');
  static final RegExp _longMaskRun = RegExp(r'\*{9,}');
  static const List<String> _shuffledCountryCodes = <String>[
    'US',
    'JP',
    'GB',
    'DE',
    'FR',
    'CA',
    'AU',
    'KR',
    'SG',
    'NL',
    'CH',
    'SE',
    'NO',
    'DK',
    'FI',
    'ES',
    'IT',
    'PT',
    'IE',
    'NZ',
  ];
  static final List<_OperatorPlaceholder> _operatorPlaceholders =
      <_OperatorPlaceholder>[];
  static Future<void>? _placeholderWarmup;

  static String redactEid(String? eid, {bool revealFull = false}) {
    if (eid == null || eid.isEmpty) return '';
    final settings = AppSettings();
    if (revealFull || settings.revealSensitiveProfileData) return eid;
    return redactEidPreview(eid);
  }

  static String redactEidPreview(String? eid) {
    if (eid == null || eid.isEmpty) return '';
    final settings = AppSettings();
    return _applyRanges(
      eid,
      ranges: [
        _Range(0, 8, settings.redactEidFirst),
        _Range(8, 24, settings.redactEidMiddle),
        _Range(eid.length - 10, eid.length, settings.redactEidLast),
      ],
    );
  }

  static String redactIccid(String iccid) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) return iccid;
    return redactIccidPreview(iccid);
  }

  static String redactIccidPreview(String iccid) {
    final settings = AppSettings();
    return _applyRanges(
      iccid,
      ranges: [
        _Range(0, 8, settings.redactIccidFirst),
        _Range(8, 14, settings.redactIccidMiddle),
        _Range(iccid.length - 6, iccid.length, settings.redactIccidLast),
      ],
    );
  }

  static String displayName(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) {
      return profile.displayName;
    }
    final hasVisibleNickname =
        profile.nickname != null &&
        profile.nickname!.trim().isNotEmpty &&
        settings.nicknameRedactionMode != NicknameRedactionMode.hideNickname;
    String base;
    if (hasVisibleNickname) {
      base = profile.displayName;
    } else if (settings.operatorRedactionMode ==
        OperatorRedactionMode.countryName) {
      base = operatorTitle(profile);
    } else {
      final shuffledPlaceholder = _shuffledPlaceholder(profile);
      if (shuffledPlaceholder != null) {
        base = shuffledPlaceholder.label;
      } else if (settings.nicknameRedactionMode ==
          NicknameRedactionMode.hideNickname) {
        base = _fallbackDisplayName(profile);
      } else {
        base = profile.displayName;
      }
    }

    if (settings.nicknameRedactionMode ==
        NicknameRedactionMode.redactPhoneNumbers) {
      return base.replaceAllMapped(
        _phoneNumber,
        (match) => _mask * match.group(0)!.length,
      );
    }
    return base;
  }

  static String? operatorSummary(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) {
      return _originalOperatorSummary(profile);
    }
    if (settings.operatorRedactionMode == OperatorRedactionMode.countryName) {
      return operatorPlaceholder(profile);
    }
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return shuffledPlaceholder.label;
    }
    return _originalOperatorSummary(profile);
  }

  static List<String> tags(List<String> source) {
    if (AppSettings().revealSensitiveProfileData) {
      return source;
    }
    if (AppSettings().tagsRedactionMode == TagsRedactionMode.hideTags) {
      return const <String>[];
    }
    return source;
  }

  static String flagUrl(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) {
      return profile.flagUrl;
    }
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return _flagUrlFromCode(shuffledPlaceholder.countryCode);
    }
    if (settings.flagRedactionMode == FlagRedactionMode.shuffledFlags) {
      final code = _shuffledCountryCode(profile.iccid);
      return _flagUrlFromCode(code);
    }
    return profile.flagUrl;
  }

  static String flagEmoji(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) {
      return profile.flagEmoji;
    }
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return _flagEmojiFromCode(shuffledPlaceholder.countryCode);
    }
    if (settings.flagRedactionMode == FlagRedactionMode.shuffledFlags) {
      return _flagEmojiFromCode(_shuffledCountryCode(profile.iccid));
    }
    return profile.flagEmoji;
  }

  static bool get hideFlag =>
      !AppSettings().revealSensitiveProfileData &&
      AppSettings().flagRedactionMode == FlagRedactionMode.hideFlag;

  static bool get hideIcon =>
      !AppSettings().revealSensitiveProfileData &&
      AppSettings().iconRedactionMode == IconRedactionMode.hideIcon;

  static bool get randomIcon =>
      !AppSettings().revealSensitiveProfileData &&
      AppSettings().iconRedactionMode == IconRedactionMode.randomIcon;

  static int stableIndex(String seed, int modulo) {
    if (modulo <= 0) return 0;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % modulo;
  }

  static String _fallbackDisplayName(EuiccProfile profile) {
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return shuffledPlaceholder.label;
    }
    if (profile.name != null && profile.name!.trim().isNotEmpty) {
      return profile.name!.trim();
    }
    if (profile.serviceProviderName != null &&
        profile.serviceProviderName!.trim().isNotEmpty) {
      return profile.serviceProviderName!.trim();
    }
    return 'Unnamed Profile';
  }

  static String? _originalOperatorSummary(EuiccProfile profile) {
    final parts = <String>[
      if (profile.serviceProviderName != null &&
          profile.serviceProviderName!.trim().isNotEmpty)
        profile.serviceProviderName!.trim(),
      if (profile.name != null &&
          profile.name!.trim().isNotEmpty &&
          profile.name!.trim() != profile.serviceProviderName?.trim())
        profile.name!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  static String countryName(EuiccProfile profile) {
    final code = profile.flag.toUpperCase();
    return _countryNames[code] ?? code;
  }

  static String operatorTitle(EuiccProfile profile) {
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return shuffledPlaceholder.label;
    }
    return countryName(profile);
  }

  static String operatorPlaceholder(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.flagRedactionMode == FlagRedactionMode.hideFlag &&
        !settings.revealSensitiveProfileData) {
      return 'Carrier';
    }
    final shuffledPlaceholder = _shuffledPlaceholder(profile);
    if (shuffledPlaceholder != null) {
      return shuffledPlaceholder.label;
    }
    final code =
        settings.flagRedactionMode == FlagRedactionMode.shuffledFlags &&
            !settings.revealSensitiveProfileData
        ? _shuffledCountryCode(profile.iccid)
        : profile.flag.toUpperCase();
    final country = _countryNames[code] ?? code;
    return '$country Carrier';
  }

  static Future<void> warmupOperatorPlaceholders() {
    return _placeholderWarmup ??= _loadOperatorPlaceholders();
  }

  static Future<void> _loadOperatorPlaceholders() async {
    try {
      final service = await ProfileMetadataService.getInstance();
      final profiles = await service.getAllProfiles();
      var changed = false;
      for (final profile in profiles) {
        final code = profile.flag.toUpperCase();
        if (code.isEmpty || code == 'UN') continue;
        final label = _placeholderLabelFromMetadata(profile);
        if (label == null) continue;
        if (_operatorPlaceholders.any(
          (placeholder) =>
              placeholder.countryCode == code && placeholder.label == label,
        )) {
          continue;
        }
        _operatorPlaceholders.add(
          _OperatorPlaceholder(countryCode: code, label: label),
        );
        changed = true;
      }
      if (changed) {
        AppSettings().refreshUi();
      }
    } finally {
      _placeholderWarmup = null;
    }
  }

  static String _applyRanges(String source, {required List<_Range> ranges}) {
    if (source.isEmpty) return source;
    final keep = List<bool>.filled(source.length, false);
    for (final range in ranges) {
      if (!range.enabled) continue;
      final start = range.start.clamp(0, source.length);
      final end = range.end.clamp(0, source.length);
      for (var i = start; i < end; i++) {
        keep[i] = true;
      }
    }

    final buffer = StringBuffer();
    for (var i = 0; i < source.length; i++) {
      buffer.write(keep[i] ? source[i] : _mask);
    }
    return buffer.toString().replaceAll(_longMaskRun, '********');
  }

  static String _shuffledCountryCode(String seed) {
    return _shuffledCountryCodes[stableIndex(
      seed,
      _shuffledCountryCodes.length,
    )];
  }

  static String _flagUrlFromCode(String code) {
    final normalized = code.length == 2 ? code.toUpperCase() : 'UN';
    final c1 = normalized[0];
    final c2 = normalized[1];
    return 'https://static.toss.im/2d-emojis/png/4x/'
        'u${_flagLetter(c1)}_u${_flagLetter(c2)}.png';
  }

  static String _flagEmojiFromCode(String code) {
    if (code.length != 2) return MccMapper.getFlagEmoji(null);
    return code
        .toUpperCase()
        .split('')
        .map((char) => String.fromCharCode(char.codeUnitAt(0) + 127397))
        .join();
  }

  static String _flagLetter(String char) {
    return (127397 + char.codeUnitAt(0)).toRadixString(16).toUpperCase();
  }

  static _OperatorPlaceholder? _shuffledPlaceholder(EuiccProfile profile) {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData ||
        settings.flagRedactionMode != FlagRedactionMode.shuffledFlags ||
        _operatorPlaceholders.isEmpty) {
      return null;
    }
    return _operatorPlaceholders[stableIndex(
      profile.iccid,
      _operatorPlaceholders.length,
    )];
  }

  static String? _placeholderLabelFromMetadata(ProfileMetadata profile) {
    final provider = profile.providerName?.trim();
    if (provider != null && provider.isNotEmpty) return provider;
    final name = profile.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    final displayName = profile.displayName.trim();
    if (displayName.isNotEmpty && displayName != 'Unknown Profile') {
      return displayName;
    }
    return null;
  }

  static const Map<String, String> _countryNames = <String, String>{
    'AD': 'Andorra',
    'AE': 'United Arab Emirates',
    'AF': 'Afghanistan',
    'AG': 'Antigua and Barbuda',
    'AI': 'Anguilla',
    'AL': 'Albania',
    'AM': 'Armenia',
    'AO': 'Angola',
    'AR': 'Argentina',
    'AT': 'Austria',
    'AU': 'Australia',
    'AW': 'Aruba',
    'AZ': 'Azerbaijan',
    'BA': 'Bosnia and Herzegovina',
    'BB': 'Barbados',
    'BD': 'Bangladesh',
    'BE': 'Belgium',
    'BF': 'Burkina Faso',
    'BG': 'Bulgaria',
    'BH': 'Bahrain',
    'BJ': 'Benin',
    'BM': 'Bermuda',
    'BN': 'Brunei',
    'BO': 'Bolivia',
    'BR': 'Brazil',
    'BS': 'Bahamas',
    'BT': 'Bhutan',
    'BW': 'Botswana',
    'BY': 'Belarus',
    'BZ': 'Belize',
    'CA': 'Canada',
    'CD': 'Democratic Republic of the Congo',
    'CF': 'Central African Republic',
    'CG': 'Republic of the Congo',
    'CH': 'Switzerland',
    'CI': "Cote d'Ivoire",
    'CL': 'Chile',
    'CM': 'Cameroon',
    'CN': 'China',
    'CO': 'Colombia',
    'CR': 'Costa Rica',
    'CU': 'Cuba',
    'CV': 'Cape Verde',
    'CW': 'Curacao',
    'CY': 'Cyprus',
    'CZ': 'Czech Republic',
    'DE': 'Germany',
    'DJ': 'Djibouti',
    'DK': 'Denmark',
    'DM': 'Dominica',
    'DO': 'Dominican Republic',
    'DZ': 'Algeria',
    'EC': 'Ecuador',
    'EE': 'Estonia',
    'EG': 'Egypt',
    'ES': 'Spain',
    'ET': 'Ethiopia',
    'FI': 'Finland',
    'FJ': 'Fiji',
    'FK': 'Falkland Islands',
    'FO': 'Faroe Islands',
    'FR': 'France',
    'GA': 'Gabon',
    'GB': 'United Kingdom',
    'GD': 'Grenada',
    'GE': 'Georgia',
    'GF': 'French Guiana',
    'GG': 'Guernsey',
    'GH': 'Ghana',
    'GI': 'Gibraltar',
    'GL': 'Greenland',
    'GM': 'Gambia',
    'GN': 'Guinea',
    'GP': 'Guadeloupe',
    'GQ': 'Equatorial Guinea',
    'GR': 'Greece',
    'GT': 'Guatemala',
    'GU': 'Guam',
    'GW': 'Guinea-Bissau',
    'GY': 'Guyana',
    'HK': 'Hong Kong',
    'HN': 'Honduras',
    'HR': 'Croatia',
    'HT': 'Haiti',
    'HU': 'Hungary',
    'ID': 'Indonesia',
    'IE': 'Ireland',
    'IL': 'Israel',
    'IM': 'Isle of Man',
    'IN': 'India',
    'IQ': 'Iraq',
    'IR': 'Iran',
    'IS': 'Iceland',
    'IT': 'Italy',
    'JE': 'Jersey',
    'JM': 'Jamaica',
    'JO': 'Jordan',
    'JP': 'Japan',
    'KE': 'Kenya',
    'KG': 'Kyrgyzstan',
    'KH': 'Cambodia',
    'KN': 'Saint Kitts and Nevis',
    'KP': 'North Korea',
    'KR': 'South Korea',
    'KW': 'Kuwait',
    'KY': 'Cayman Islands',
    'KZ': 'Kazakhstan',
    'LA': 'Laos',
    'LB': 'Lebanon',
    'LC': 'Saint Lucia',
    'LI': 'Liechtenstein',
    'LK': 'Sri Lanka',
    'LR': 'Liberia',
    'LS': 'Lesotho',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'LV': 'Latvia',
    'LY': 'Libya',
    'MA': 'Morocco',
    'MC': 'Monaco',
    'MD': 'Moldova',
    'ME': 'Montenegro',
    'MF': 'Saint Martin',
    'MG': 'Madagascar',
    'MK': 'North Macedonia',
    'ML': 'Mali',
    'MM': 'Myanmar',
    'MN': 'Mongolia',
    'MO': 'Macao',
    'MQ': 'Martinique',
    'MR': 'Mauritania',
    'MS': 'Montserrat',
    'MT': 'Malta',
    'MU': 'Mauritius',
    'MV': 'Maldives',
    'MW': 'Malawi',
    'MX': 'Mexico',
    'MY': 'Malaysia',
    'MZ': 'Mozambique',
    'NA': 'Namibia',
    'NC': 'New Caledonia',
    'NE': 'Niger',
    'NG': 'Nigeria',
    'NI': 'Nicaragua',
    'NL': 'Netherlands',
    'NO': 'Norway',
    'NP': 'Nepal',
    'NZ': 'New Zealand',
    'OM': 'Oman',
    'PA': 'Panama',
    'PE': 'Peru',
    'PG': 'Papua New Guinea',
    'PH': 'Philippines',
    'PK': 'Pakistan',
    'PL': 'Poland',
    'PM': 'Saint Pierre and Miquelon',
    'PR': 'Puerto Rico',
    'PS': 'Palestine',
    'PT': 'Portugal',
    'PY': 'Paraguay',
    'QA': 'Qatar',
    'RO': 'Romania',
    'RS': 'Serbia',
    'RU': 'Russia',
    'RW': 'Rwanda',
    'SA': 'Saudi Arabia',
    'SC': 'Seychelles',
    'SD': 'Sudan',
    'SE': 'Sweden',
    'SG': 'Singapore',
    'SI': 'Slovenia',
    'SK': 'Slovakia',
    'SL': 'Sierra Leone',
    'SM': 'San Marino',
    'SN': 'Senegal',
    'SO': 'Somalia',
    'SR': 'Suriname',
    'SV': 'El Salvador',
    'SX': 'Sint Maarten',
    'SY': 'Syria',
    'SZ': 'Eswatini',
    'TC': 'Turks and Caicos Islands',
    'TD': 'Chad',
    'TG': 'Togo',
    'TH': 'Thailand',
    'TJ': 'Tajikistan',
    'TL': 'Timor-Leste',
    'TM': 'Turkmenistan',
    'TN': 'Tunisia',
    'TO': 'Tonga',
    'TR': 'Turkey',
    'TT': 'Trinidad and Tobago',
    'TW': 'Taiwan',
    'TZ': 'Tanzania',
    'UA': 'Ukraine',
    'UG': 'Uganda',
    'UN': 'Unknown',
    'US': 'United States',
    'UY': 'Uruguay',
    'UZ': 'Uzbekistan',
    'VA': 'Vatican City',
    'VC': 'Saint Vincent and the Grenadines',
    'VE': 'Venezuela',
    'VG': 'British Virgin Islands',
    'VI': 'United States Virgin Islands',
    'VN': 'Vietnam',
    'YE': 'Yemen',
    'ZA': 'South Africa',
    'ZM': 'Zambia',
    'ZW': 'Zimbabwe',
  };
}

class _OperatorPlaceholder {
  final String countryCode;
  final String label;

  const _OperatorPlaceholder({required this.countryCode, required this.label});
}

class _Range {
  final int start;
  final int end;
  final bool enabled;

  const _Range(this.start, this.end, this.enabled);
}
