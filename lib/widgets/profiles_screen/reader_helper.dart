import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ReaderHelper {
  static IconData getIconData(String? reader) {
    if (reader == null) return Icons.devices_other_rounded;

    if (reader.startsWith('red_ble:') ||
        reader.startsWith('red_ble2:') ||
        reader.startsWith('simlink:')) {
      return Icons.bluetooth_rounded;
    }

    if (reader.startsWith('omapi:')) {
      return Icons.sim_card_rounded;
    }

    if (reader.startsWith('tmapi:') || reader.contains('|telephony:')) {
      return Icons.smartphone_rounded;
    }

    if (reader.startsWith('remocard:')) {
      return Icons.cloud_rounded;
    }

    if (reader.startsWith('qrtr:') || reader.startsWith('hal:')) {
      return Icons.memory_rounded;
    }

    return Icons.usb_rounded;
  }

  static Color? getIconColor(
    String? reader,
    BuildContext context, {
    Color? overrideColor,
  }) {
    // If override color provided, respect it (but we might ignore it for specific types if desired,
    // but usually overrideColor is used for "selected" state).
    // If overrideColor is provided, we usually just return it OR mixed.
    // However, the original code had specific colors for BLE/Simlink etc.

    // If selected (overrideColor is not null (e.g. primary)), we might want to stick to primary or mix.
    // But let's follow the previous pattern: use specific colors unless selected?
    // In ReaderDropdown, we saw: `color: isSelected ? theme.colorScheme.primary : null`.
    // And inside `_getReaderIcon`: `color: color ?? (isDark ? ...)`
    // So if `color` is passed, it uses it.

    if (overrideColor != null) return overrideColor;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultSubtle = AppTheme.onSurfaceSubtle(context);

    if (reader == null) return defaultSubtle;

    if (reader.startsWith('red_ble:') || reader.startsWith('red_ble2:')) {
      return isDark ? Colors.blue[300] : Colors.blue[600];
    }

    if (reader.startsWith('simlink:')) {
      return isDark ? Colors.orange[300] : Colors.orange;
    }

    if (reader.startsWith('omapi:')) {
      return AppTheme.simCardIconColor(context);
    }

    if (reader.startsWith('tmapi:') || reader.contains('|telephony:')) {
      return isDark ? Colors.teal[300] : Colors.teal[600];
    }

    if (reader.startsWith('remocard:')) {
      return isDark ? Colors.purple[300] : Colors.purple[600];
    }

    return defaultSubtle;
  }

  static bool isPersistent(String? readerId) {
    if (readerId == null) return false;
    return readerId.startsWith('remocard:') ||
        readerId.startsWith('red_ble:') ||
        readerId.startsWith('red_ble2:') ||
        readerId.startsWith('simlink:');
  }
}
