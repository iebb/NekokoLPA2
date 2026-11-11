import 'package:flutter/material.dart';
import '../models/activation_code.dart';
import '../theme/app_theme.dart';

class LpaTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String text = this.text;
    final theme = Theme.of(context);

    // For batch download, we might have multiple lines, each starting with LPA:1$
    // We'll highlight line by line
    final lines = text.split('\n');
    final List<TextSpan> children = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('LPA:1\$')) {
        children.add(TextSpan(text: line, style: style));
      } else {
        final parts = line.split('\$');

        // LPA:1
        children.add(
          TextSpan(
            text: parts[0],
            style: style?.copyWith(color: style.color?.withValues(alpha: 0.5)),
          ),
        );

        // SM-DP+ Address
        if (parts.length > 1) {
          children.add(
            TextSpan(
              text: '\$',
              style: style?.copyWith(
                color: style.color?.withValues(alpha: 0.5),
              ),
            ),
          );
          final val = parts[1];
          final color = ActivationCode.smdpFqdnPattern.hasMatch(val)
              ? AppTheme.smdpAddress(context)
              : theme.colorScheme.error;
          children.add(
            TextSpan(
              text: val,
              style: style?.copyWith(color: color),
            ),
          );
        }

        // Matching ID
        if (parts.length > 2) {
          children.add(
            TextSpan(
              text: '\$',
              style: style?.copyWith(
                color: style.color?.withValues(alpha: 0.5),
              ),
            ),
          );
          final val = parts[2];
          final color = ActivationCode.matchingIdPattern.hasMatch(val)
              ? AppTheme.matchingId(context)
              : theme.colorScheme.error;
          children.add(
            TextSpan(
              text: val,
              style: style?.copyWith(color: color),
            ),
          );
        }

        // SM-DP+ OID
        if (parts.length > 3) {
          children.add(
            TextSpan(
              text: '\$',
              style: style?.copyWith(
                color: style.color?.withValues(alpha: 0.5),
              ),
            ),
          );
          final val = parts[3];
          final color = (val.isEmpty || ActivationCode.oidPattern.hasMatch(val))
              ? AppTheme.smdpOid(context)
              : theme.colorScheme.error;
          children.add(
            TextSpan(
              text: val,
              style: style?.copyWith(color: color),
            ),
          );
        }

        // Confirmation Code
        if (parts.length > 4) {
          children.add(
            TextSpan(
              text: '\$',
              style: style?.copyWith(
                color: style.color?.withValues(alpha: 0.5),
              ),
            ),
          );
          children.add(
            TextSpan(
              text: parts[4],
              style: style?.copyWith(color: AppTheme.confirmationCode(context)),
            ),
          );
        }

        if (parts.length > 5) {
          for (int j = 5; j < parts.length; j++) {
            children.add(
              TextSpan(
                text: '\$',
                style: style?.copyWith(
                  color: style.color?.withValues(alpha: 0.5),
                ),
              ),
            );
            children.add(TextSpan(text: parts[j], style: style));
          }
        }
      }

      if (i < lines.length - 1) {
        children.add(TextSpan(text: '\n', style: style));
      }
    }

    return TextSpan(style: style, children: children);
  }
}
