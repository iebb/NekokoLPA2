import 'package:flutter/material.dart';
import '../models/profile_card_bottom_data.dart';
import '../theme/app_theme.dart';
import '../utils/profile_redaction.dart';
import '../utils/size_formatter.dart';

class ProfileCardBottom extends StatelessWidget {
  final Color themeColor;
  final String? phoneNumber;
  final String? lineExpiry;
  final String? balance;
  final List<ProfilePackage> packages;

  const ProfileCardBottom({
    super.key,
    required this.themeColor,
    this.phoneNumber,
    this.lineExpiry,
    this.balance,
    this.packages = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (phoneNumber == null && balance == null && packages.isEmpty) {
      return const SizedBox.shrink();
    }

    // The profiles screen rebuilds on AppSettings changes, so these pick up
    // the current eye state (reveal / mask as configured / full-hide).
    final displayPhoneNumber = phoneNumber == null
        ? null
        : ProfileRedaction.redactPhoneNumber(phoneNumber);
    final displayBalance = balance == null
        ? null
        : ProfileRedaction.redactBalance(balance);

    // Calculate darker shades for text
    // Calculate colors based on theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsv = HSVColor.fromColor(themeColor);

    final Color textColor;
    final Color iconColor;
    final Color subTextColor;

    if (isDark) {
      textColor = const Color(0xFFE2E8F0); // Slate 200
      subTextColor = const Color(0xFF94A3B8); // Slate 400
      // Make sure icon/accent color is bright enough for dark mode
      iconColor = hsv.withValue(1.0).withSaturation(0.7).toColor();
    } else {
      textColor = hsv.withValue(hsv.value * 0.5).toColor(); // Darker for text
      subTextColor = hsv.withValue(hsv.value * 0.6).toColor();
      iconColor = hsv.withValue(hsv.value * 0.8).toColor();
    }

    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: themeColor.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Phone Number + Expiry | Balance
            if (phoneNumber != null || balance != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (phoneNumber != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 11,
                            color: isDark ? subTextColor : iconColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayPhoneNumber!,
                              style: TextStyle(
                                fontSize: 11,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lineExpiry != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              "Expires: ${_formatDate(lineExpiry!)}",
                              style: TextStyle(
                                fontSize: 10,
                                color: subTextColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (balance != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          displayBalance!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // Packages
            if (packages.isNotEmpty) ...[
              if (phoneNumber != null || balance != null)
                const SizedBox(height: 6),
              ...packages.map(
                (pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package Name
                      Text(
                        pkg.name,
                        style: AppTheme.badgeTextStyle(context, iconColor)
                            .copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold, // Title a bit bolder
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),

                      // Expiry & Usage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Expiry
                          Expanded(
                            child: pkg.expiry != null
                                ? Text(
                                    "Exp: ${_formatDate(pkg.expiry!)}",
                                    style: AppTheme.badgeTextStyle(
                                      context,
                                      isDark
                                          ? subTextColor
                                          : iconColor.withValues(alpha: 0.8),
                                    ).copyWith(fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Usage
                          Text(
                            "${SizeFormatter.format(pkg.remainingBytes.toInt())} / ${SizeFormatter.format(pkg.totalBytes.toInt())}",
                            style: AppTheme.badgeTextStyle(context, iconColor)
                                .copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      LinearProgressIndicator(
                        value: pkg.progress,
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        color: themeColor.withValues(alpha: 0.8),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateStr.split('T').first.split(' ').first;
    }
  }
}
