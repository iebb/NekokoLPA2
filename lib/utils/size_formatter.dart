import '../settings/app_settings.dart';

class SizeFormatter {
  static String format(int? bytes, {int precision = 2}) {
    if (bytes == null) return "Unknown";

    final unit = AppSettings().sizeUnit;
    switch (unit) {
      case "settings_item_unit_b":
        return "${_withCommas(bytes)} B";
      case "settings_item_unit_kb":
        return "${_withCommas((bytes / 1000).toStringAsFixed(precision))} kB";
      case "settings_item_unit_kib":
        return "${_withCommas((bytes / 1024).toStringAsFixed(precision))} kiB";
      case "settings_item_unit_adaptive_bi":
        if (bytes < 1024) return "${_withCommas(bytes)} B";
        if (bytes < 1024 * 1024) {
          return "${_withCommas((bytes / 1024).toStringAsFixed(precision))} kiB";
        }
        if (bytes < 1024 * 1024 * 1024) {
          return "${_withCommas((bytes / (1024 * 1024)).toStringAsFixed(precision))} MiB";
        }
        return "${_withCommas((bytes / (1024 * 1024 * 1024)).toStringAsFixed(precision))} GiB";
      case "settings_item_unit_adaptive_si":
      default:
        // Default: 1024-based scaling labeled as KB/MB/GB, 2 decimal places
        if (bytes < 1024) return "${_withCommas(bytes)} B";
        if (bytes < 1024 * 1024) {
          return "${_withCommas((bytes / 1024).toStringAsFixed(precision))} KB";
        }
        if (bytes < 1024 * 1024 * 1024) {
          return "${_withCommas((bytes / (1024 * 1024)).toStringAsFixed(precision))} MB";
        }
        return "${_withCommas((bytes / (1024 * 1024 * 1024)).toStringAsFixed(precision))} GB";
    }
  }

  static final RegExp _thousands = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  static String _withCommas(dynamic number) {
    String str = number.toString();
    List<String> parts = str.split('.');
    parts[0] = parts[0].replaceAllMapped(_thousands, (Match m) => '${m[1]},');
    return parts.join('.');
  }
}
